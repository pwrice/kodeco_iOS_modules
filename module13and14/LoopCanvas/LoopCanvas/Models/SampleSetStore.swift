//
//  SampleSetStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 9/21/24.
//

import Foundation
import os
import Combine

struct LocalSampleSet: Hashable, Codable {
  let name: String
  let tempo: Double
}

struct RemoteSampleSetCategory: Codable {
  let name: String
  let loops: [RemoteSampleSetLoop]
}

struct RemoteSampleSetLoop: Codable {
  let url: String
}

struct RemoteSampleSet: Codable {
  let name: String
  let url: String
  let tempo: Double
  let categories: [RemoteSampleSetCategory]
}

struct RemoteSampleSetIndex: Codable {
  let sampleSets: [RemoteSampleSet]
}

enum RemoteSampleSetIndexLoadingState {
  case notLoaded,
    loading,
    loaded,
    error
}


// Index File URL
// https://loopcanvas.s3.amazonaws.com/Samples/SampleSetIndex.json

class SampleSetStore: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: SampleSetStore.self)
  )

  let urlSessionLoader: URLSessionLoading

  @Published var remoteSampleSetIndexLoadingState = RemoteSampleSetIndexLoadingState.notLoaded
  @Published var errorDownloadingSampleSets = false
  @Published var downloadableSampleSets: [DownloadableSampleSet] = []
  @Published var localSampleSets: [LocalSampleSet] = []

  var usingMockResults = false
  var mockErrorState: RemoteSampleSetIndexLoadingState?
  var mockErrorDownloadingSampleSets: Bool?

  let remoteSampleSetS3Path = "https://loopcanvas.s3.amazonaws.com/Samples/"
  var localSamplesDirectory = "Samples"
  var baseSampleSetsRemoteURL: URL?
  var baseSampleSetsLocalURL: URL

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initializers

  /// Default initializer using a standard URLSession loader.
  convenience init () {
    self.init(urlSessionLoader: URLSessionLoader())
  }

  /// Mock initializer for testing with predefined JSON and error states.
  /// - Parameters:
  ///   - fileName: The name of the mock JSON file.
  ///   - mockErrorState: Optional mock error state.
  ///   - mockErrorDownloadingSampleSets: Optional mock download error flag.
  convenience init(
    withMockResults fileName: String,
    mockErrorState: RemoteSampleSetIndexLoadingState? = nil,
    mockErrorDownloadingSampleSets: Bool? = nil
  ) {
    let mockJSONURL = URL(
      fileURLWithPath: fileName,
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(url: mockJSONURL, statusCode: 200, httpVersion: "2.2", headerFields: nil)!
    let mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    self.init(urlSessionLoader: mockUrlSessionLoader)

    loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
    usingMockResults = true
    self.mockErrorState = mockErrorState
    self.mockErrorDownloadingSampleSets = mockErrorDownloadingSampleSets
  }

  /// Designated initializer with a URL session loader.
  /// - Parameter urlSessionLoader: A loader for network requests.
  init (urlSessionLoader: URLSessionLoading) {
    baseSampleSetsRemoteURL = URL(string: remoteSampleSetS3Path)
    self.urlSessionLoader = urlSessionLoader
    // Initialize user-writable Samples directory under Documents/LoopCanvas/Samples
    self.baseSampleSetsLocalURL = Self.setupUserSamplesDirectoryAndCopyDefaultsIfNeeded(bundleSamplesSubdirectoryName: localSamplesDirectory)
  }

  /// Returns the URL to a specific library folder inside the user-writable Samples directory
  /// - Parameter libraryFolderName: The name of the library (sample set) folder
  /// - Returns: URL pointing to Documents/LoopCanvas/Samples/<libraryFolderName>
  func libraryDirectoryURL(for libraryFolderName: String) -> URL {
    return baseSampleSetsLocalURL.appendingPathComponent(libraryFolderName, isDirectory: true)
  }

  /// Ensures a user-writable Samples directory exists at Documents/LoopCanvas/Samples,
  /// and copies default bundled SampleSets into it if they are not present.
  /// - Parameter bundleSamplesSubdirectoryName: The name of the Samples directory inside the app bundle (e.g., "Samples").
  /// - Returns: The URL to the user-writable Samples directory.
  static func setupUserSamplesDirectoryAndCopyDefaultsIfNeeded(bundleSamplesSubdirectoryName: String) -> URL {
    let fileManager = FileManager.default

    // Documents directory for the app sandbox
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let loopCanvasURL = documentsURL.appendingPathComponent("LoopCanvas", isDirectory: true)
    let userSamplesURL = loopCanvasURL.appendingPathComponent("Samples", isDirectory: true)

    print(">> documentsURL \(documentsURL)")
    print(">> loopCanvasURL \(loopCanvasURL)")
    print(">> userSamplesURL \(userSamplesURL)")

    // Create LoopCanvas and Samples directories if they do not exist
    do {
      if !fileManager.fileExists(atPath: loopCanvasURL.path) {
        try fileManager.createDirectory(at: loopCanvasURL, withIntermediateDirectories: true)
        print(">> created loopCanvasURL")
      }
      if !fileManager.fileExists(atPath: userSamplesURL.path) {
        try fileManager.createDirectory(at: userSamplesURL, withIntermediateDirectories: true)
        print(">> created userSamplesURL")
      }
    } catch {
      Self.logger.error("Failed to create user samples directories: \(String(describing: error))")
    }

    // Locate bundled default Samples directory
    let bundleBaseURL = Bundle.main.bundleURL
    let bundledSamplesURL = URL(fileURLWithPath: bundleSamplesSubdirectoryName, relativeTo: bundleBaseURL)

    // Copy each default SampleSet folder (subdirectory) if not already present in userSamplesURL
    do {
      if let bundledContents = try? fileManager.contentsOfDirectory(at: bundledSamplesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
        for item in bundledContents {
          // Only consider directories (each default SampleSet is a subdirectory)
          if (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            let destination = userSamplesURL.appendingPathComponent(item.lastPathComponent, isDirectory: true)
            if !fileManager.fileExists(atPath: destination.path) {
              do {
                try fileManager.copyItem(at: item, to: destination)
                print(">> copying \(item)")
                print(">> to \(destination)")
              } catch {
                Self.logger.error("Failed to copy default SampleSet \(item.lastPathComponent) to user directory: \(String(describing: error))")
              }
            }
          }
        }
      }
    }

    return userSamplesURL
  }

  /// Loads the remote sample set index.
  /// Sets up downloadableSampleSets published property.
  public func loadRemoteSampleSetIndex() {
    if usingMockResults {
      // When using mock results, ignore calls to reload sampleset index
      if let mockErrorState = mockErrorState {
        remoteSampleSetIndexLoadingState = mockErrorState
      } else {
        remoteSampleSetIndexLoadingState = .loaded
      }
      if let mockErrorDownloadingSampleSets = mockErrorDownloadingSampleSets {
        errorDownloadingSampleSets = mockErrorDownloadingSampleSets
      }
      return
    }
    guard let baseUrl = baseSampleSetsRemoteURL else {
      Self.logger.error("Error constructing baseUrl from \(self.remoteSampleSetS3Path)")
      remoteSampleSetIndexLoadingState = .error
      return
    }
    let sampleIndexUrl = baseUrl.appendingPathComponent("SampleSetIndex.json")

    remoteSampleSetIndexLoadingState = .loading

    let sampleIndexRequest = URLRequest(url: sampleIndexUrl)
    urlSessionLoader.fetchDataFromURL(urlRequest: sampleIndexRequest) { [weak self] data, response, error in
      self?.processRemoteSampleSetIndexResponse(data: data, response: response, error: error)
    }
  }

  /// Loads local sample sets from the filesystem.
  public func loadLocalSampleSets() {
    let fileManager = FileManager.default
    var localSampleSets: [LocalSampleSet] = []
    do {
      let sampleSetFolders = try fileManager.contentsOfDirectory(
        at: baseSampleSetsLocalURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles])
      for sampleSetFolderUrl in sampleSetFolders where sampleSetFolderUrl.hasDirectoryPath {
        do {
          let sampleSetJsonURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: sampleSetFolderUrl)
          let decoder = JSONDecoder()
          let sampleSetJSONData = try Data(contentsOf: sampleSetJsonURL)
          let sampleSet = try decoder.decode(LocalSampleSet.self, from: sampleSetJSONData)
          localSampleSets.append(sampleSet)
        } catch {
          Self.logger.error("Error loading library SampleSetInfo.json from JSON \(error)")
        }
      }
    } catch {
      Self.logger.error("Error loading sampleSets from samples directory \(self.baseSampleSetsLocalURL) \(error)")
    }

    self.localSampleSets = localSampleSets
  }

  /// Downloads a remote sample set.
  public func downloadRemoteSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    Task {
      await remoteSampleSet.downloadSampleSet()
    }
  }

  /// Removes a locally stored sample set and directory in local filesystem
  public func removeLocalSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    remoteSampleSet.removeSampleSetDownload()
    loadLocalSampleSets()
  }

  func processRemoteSampleSetIndexResponse(data: Data?, response: URLResponse?, error: Error?) {
    if let data = data, let response = response as? HTTPURLResponse {
      if response.statusCode != 200 {
        Task { @MainActor in
          remoteSampleSetIndexLoadingState = .error
        }
      }

      do {
        let decoder = JSONDecoder()
        let sampleSetIndex = try decoder.decode(RemoteSampleSetIndex.self, from: data)
        let sampleSets = augmentRemoteSampleSetsWithDownloadedState(sampleSetIndex.sampleSets)

        Task { @MainActor in
          downloadableSampleSets = sampleSets
          remoteSampleSetIndexLoadingState = .loaded
          monitorSampleSetLoadingStates()
        }
      } catch let error {
        Self.logger.error("Error decoding RemoteSampleSetIndex response \(String(describing: error))")
        Task { @MainActor in
          remoteSampleSetIndexLoadingState = .error
        }
      }
    } else {
      Self.logger.error("Contents fetch failed: \(error?.localizedDescription ?? "Unknown error")")
      Task { @MainActor in
        remoteSampleSetIndexLoadingState = .error
      }
    }
  }

  private func monitorSampleSetLoadingStates() {
    let loadingStatePublishers = downloadableSampleSets.map { $0.$loadingState.eraseToAnyPublisher() }

    Publishers.MergeMany(loadingStatePublishers)
      .sink { [weak self] newState in
        self?.errorDownloadingSampleSets = newState == .error || (self?.downloadableSampleSets.contains { $0.loadingState == .error } ?? false)
      }
      .store(in: &cancellables)
  }

  private func augmentRemoteSampleSetsWithDownloadedState(_ sampleSets: [RemoteSampleSet]) -> [DownloadableSampleSet] {
    guard let baseSampleSetsRemoteURL = baseSampleSetsRemoteURL else {
      Self.logger.error("Error accessing and baseSampleSetsRemoteURL")
      Task { @MainActor in
        remoteSampleSetIndexLoadingState = .error
      }
      return []
    }

    return sampleSets.map { sampleSet in
      DownloadableSampleSet(
        remoteSampleSet: sampleSet,
        loadingState: localSampleSets.contains { $0.name == sampleSet.name } ? .loaded : .notLoaded,
        baseSampleSetsRemoteURL: baseSampleSetsRemoteURL,
        baseSampleSetsLocalURL: baseSampleSetsLocalURL
      )
    }
  }
}
