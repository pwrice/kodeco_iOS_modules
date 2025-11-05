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
  var baseSampleSetsRemoteURL: URL?
  let localSamplesDirectory = "Samples/"
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
    baseSampleSetsLocalURL = URL(
      fileURLWithPath: localSamplesDirectory,
      relativeTo: Bundle.main.bundleURL)
    self.urlSessionLoader = urlSessionLoader
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
