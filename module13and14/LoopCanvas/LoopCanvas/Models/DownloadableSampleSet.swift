//
//  DownloadableSampleSet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/21/24.
//

import Foundation
import os

enum DownloadableSampleSetLoadingState {
  case notLoaded,
    loading,
    loaded,
    error
}


class DownloadableSampleSet: ObservableObject, Identifiable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: DownloadableSampleSet.self)
  )

  let baseSampleSetRemoteURL: URL
  let baseSampleSetLocalURL: URL
  var id: String { remoteSampleSet.name }
  let remoteSampleSet: RemoteSampleSet

  @Published var loadingState: DownloadableSampleSetLoadingState
  @Published var downloadProgress: Double = 0.0

  /// Initializes a `DownloadableSampleSet` instance with URLs and a remote sample set.
  ///
  /// - Parameters:
  ///   - remoteSampleSet: The metadata and structure of the remote sample set.
  ///   - loadingState: The initial loading state of the sample set.
  ///   - baseSampleSetsRemoteURL: The base URL for downloading sample files.
  ///   - baseSampleSetsLocalURL: The base local directory for storing sample files.
  init(
    remoteSampleSet: RemoteSampleSet,
    loadingState: DownloadableSampleSetLoadingState,
    baseSampleSetsRemoteURL: URL,
    baseSampleSetsLocalURL: URL
  ) {
    self.remoteSampleSet = remoteSampleSet
    self.loadingState = loadingState
    self.baseSampleSetRemoteURL = baseSampleSetsRemoteURL.appendingPathComponent(
      remoteSampleSet.name, isDirectory: true)
    self.baseSampleSetLocalURL = baseSampleSetsLocalURL.appendingPathComponent(remoteSampleSet.name, isDirectory: true)
  }

  /// Removes the downloaded sample set from the local directory.
  ///
  /// This method clears all locally stored files and resets the loading state to `.notLoaded`.
  public func removeSampleSetDownload() {
    deleteLocalSampleSetDirectory()
    loadingState = .notLoaded
  }

  /// Asynchronously downloads the sample set from the remote server.
  ///
  /// This method clears any existing local sample set directory, creates new directories,
  /// and begins downloading files using `FileDownloadManager`.
  ///
  /// - Note: This method updates the `loadingState` and `downloadProgress` properties.
  ///
  /// - Throws: An error if the download process fails.
  public func downloadSampleSet() async {
    Task { @MainActor in
      loadingState = .loading
      downloadProgress = 0.0
    }
    Self.logger.debug("baseSampleSetLocalUrl \(self.baseSampleSetLocalURL)")

    // Remove existing local sample set directory
    deleteLocalSampleSetDirectory()

    // Calculate URLs
    let remoteAndLocalURLPairs = getRemoteAndLocalURLPairs()
    let remoteUrls = remoteAndLocalURLPairs.map(\.0)
    let destinationFolders = remoteAndLocalURLPairs.map(\.1)
    Self.logger.debug("remoteUrls \(remoteUrls)")
    Self.logger.debug("destinationFolders \(destinationFolders)")

    // Create new local directories
    createLocalDirectories(destinationFolders: destinationFolders)

    // Download files with FileDownloadManager
    do {
      let downloadedFiles = try await FileDownloadManager.shared.downloadFiles(
        from: remoteUrls,
        to: destinationFolders
      ) { progress in
        Self.logger.debug("Overall Progress: \(Int(progress * 100))%")

        Task { @MainActor in
          self.downloadProgress = progress
        }
      }

      Task { @MainActor in
        loadingState = .loaded
      }

      for (originalURL, localURL) in downloadedFiles {
        Self.logger.debug("Downloaded: \(originalURL) -> \(localURL)")
      }
    } catch {
      Self.logger.debug("Download failed: \(error)")
      Task { @MainActor in
        loadingState = .error
      }
    }
  }
}


extension DownloadableSampleSet {
  /// Generates pairs of remote and local URLs for sample set files.
  ///
  /// - Returns: An array of tuples containing remote and local file URLs.
  ///
  /// - Example Output:
  ///   `[("remote/file1", "local/file1"), ("remote/file2", "local/file2")]`
  func getRemoteAndLocalURLPairs() -> [(URL, URL)] {
    var urls: [(URL, URL)] = []

    let sampleSetJsonRemoteURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: baseSampleSetRemoteURL)
    Self.logger.debug("sampleSetJsonRemoteURL \(sampleSetJsonRemoteURL)")
    let sampleSetJsonLocalURL = baseSampleSetLocalURL
    Self.logger.debug("sampleSetJsonLocalURL \(sampleSetJsonLocalURL)")
    urls.append((sampleSetJsonRemoteURL, sampleSetJsonLocalURL))

    for catagory in remoteSampleSet.categories {
      let categoryLocalUrl = baseSampleSetLocalURL.appendingPathComponent(catagory.name, isDirectory: true)
      for sample in catagory.loops {
        let sampleRemoteUrl = URL(fileURLWithPath: sample.url, relativeTo: baseSampleSetRemoteURL)
        urls.append((sampleRemoteUrl, categoryLocalUrl))
      }
    }

    return urls
  }

  /// Creates local directories for downloaded sample files.
  ///
  /// - Parameter destinationFolders: An array of local directory URLs to create.
  ///
  /// - Throws: An error if any directory creation fails.
  private func createLocalDirectories(destinationFolders: [URL]) {
    do {
      let fileManager = FileManager.default
      for localUrl in destinationFolders where !fileManager.fileExists(atPath: localUrl.path) {
        Self.logger.info("Creating SampleSet directory: \(localUrl)")
        try fileManager.createDirectory(at: localUrl, withIntermediateDirectories: true)
      }
    } catch {
      loadingState = .error
      Self.logger.error("Error creating new SampleSet directories: \(error)")
    }
  }

  /// Deletes the local directory containing the downloaded sample set.
  ///
  /// - Throws: An error if the directory cannot be deleted.
  private func deleteLocalSampleSetDirectory() {
    // Remove existing local sample set directory
    Self.logger.debug("removing directory  \(self.baseSampleSetLocalURL)")
    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: baseSampleSetLocalURL.path) {
        try fileManager.removeItem(at: baseSampleSetLocalURL)
      }
    } catch {
      loadingState = .error
      Self.logger.error("Error removing existing sampleset diretory: \(error)")
    }
  }
}
