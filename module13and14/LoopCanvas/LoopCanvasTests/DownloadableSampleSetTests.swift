//
//  DownloadableSampleSetTests.swift
//  LoopCanvas
//
//  Created by Peter Rice on 1/1/25.
//

import XCTest
import Combine
@testable import LoopCanvas

final class DownloadableSampleSetTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []
  var mockUrlSessionLoader: MockURLSessionLoader!
  var store: SampleSetStore!
  let testDirectory = FileManager.default.temporaryDirectory.appending(path: "DownloadableSampleSetTests")

  override func setUpWithError() throws {
    let mockJSONURL = URL(
      fileURLWithPath: "Samples/SampleSetIndex.json",
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(
      url: mockJSONURL,
      statusCode: 200,
      httpVersion: "2.2",
      headerFields: nil
    )!
    mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    store = SampleSetStore(urlSessionLoader: mockUrlSessionLoader)

    // Setup temporary directory for deleting / downloading genres
    let fileManager = FileManager.default
    if fileManager.fileExists(atPath: testDirectory.path) {
      try fileManager.removeItem(at: testDirectory)
    }
    store.baseSampleSetsLocalURL = testDirectory
  }

  override func tearDown() {
    cancellables.removeAll()
    super.tearDown()
  }

  func testDownloadableSampleSetInitialState() throws {
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()
    XCTAssertEqual(dubSampleSet.remoteSampleSet.tempo, 80)

    XCTAssertEqual(dubSampleSet.loadingState, .notLoaded)
    XCTAssertEqual(dubSampleSet.downloadProgress, 0)
    XCTAssertEqual(dubSampleSet.baseSampleSetRemoteURL.path, "/Samples/Dub")
  }

  func testRemoveSampleSetDownload() throws {
    let fileManager = FileManager.default
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()

    let sampleSetsLocalURL = URL(
      fileURLWithPath: store.localSamplesDirectory,
      relativeTo: Bundle.main.bundleURL).appendingPathComponent("Dub")
    let testSampleSetsLocalURL = testDirectory.appendingPathComponent("Dub")

    // The SampleSet local directory does not exist initially
    XCTAssertFalse(fileManager.fileExists(atPath: dubSampleSet.baseSampleSetLocalURL.path))

    // Copy sample set directoy at sampleSetsLocalURL to test directory
    try copyDirectoryContents(from: sampleSetsLocalURL, to: testSampleSetsLocalURL)

    // Verify SampleSet local directory exists
    XCTAssertTrue(fileManager.fileExists(atPath: dubSampleSet.baseSampleSetLocalURL.path))

    // Delete sample set locally
    dubSampleSet.removeSampleSetDownload()

    // Verify SampleSet local directory no longer exists
    XCTAssertFalse(fileManager.fileExists(atPath: dubSampleSet.baseSampleSetLocalURL.path))
  }

  func testGetRemoteAndLocalURLPairs() throws {
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()

    let urlPairs = dubSampleSet.getRemoteAndLocalURLPairs()
    XCTAssertEqual(urlPairs.count, 49)
    XCTAssertEqual(urlPairs[0].0.path, "/Samples/Dub/SampleSetInfo.json")
    XCTAssertEqual(
      urlPairs[0].1.path,
      testDirectory.appendingPathComponent("Dub").path
    )

    let localBassCategoryUrl = testDirectory.appendingPathComponent("Dub/Bass")
    XCTAssertEqual(urlPairs[1].0.path, "/Samples/Dub/Bass/Bass-3.wav")
    XCTAssertEqual(urlPairs[1].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[2].0.path, "/Samples/Dub/Bass/Bass-4.wav")
    XCTAssertEqual(urlPairs[2].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[3].0.path, "/Samples/Dub/Bass/Bass-5.wav")
    XCTAssertEqual(urlPairs[3].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[4].0.path, "/Samples/Dub/Bass/Bass-6.wav")
    XCTAssertEqual(urlPairs[4].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[5].0.path, "/Samples/Dub/Bass/Midi Bass-1.wav")
    XCTAssertEqual(urlPairs[5].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[6].0.path, "/Samples/Dub/Bass/Midi Bass-2.wav")
    XCTAssertEqual(urlPairs[6].1.path, localBassCategoryUrl.path)

    let localDrumsCategoryUrl = testDirectory.appendingPathComponent("Dub/Drums")
    XCTAssertEqual(urlPairs[7].0.path, "/Samples/Dub/Drums/Drums-1.wav")
    XCTAssertEqual(urlPairs[7].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[8].0.path, "/Samples/Dub/Drums/Drums-2.wav")
    XCTAssertEqual(urlPairs[8].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[9].0.path, "/Samples/Dub/Drums/Drums-3.wav")
    XCTAssertEqual(urlPairs[9].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[10].0.path, "/Samples/Dub/Drums/Drums-4.wav")
    XCTAssertEqual(urlPairs[10].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[11].0.path, "/Samples/Dub/Drums/Drums-5.wav")
    XCTAssertEqual(urlPairs[11].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[12].0.path, "/Samples/Dub/Drums/Drums-6.wav")
    XCTAssertEqual(urlPairs[12].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[13].0.path, "/Samples/Dub/Drums/Drums-7.wav")
    XCTAssertEqual(urlPairs[13].1.path, localDrumsCategoryUrl.path)
  }

  func testDownloadSampleSet() async throws {
    let fileManager = FileManager.default
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()
    let urlPairs = dubSampleSet.getRemoteAndLocalURLPairs()
    var progressValues: [Double] = []
    var observedLoadingStates: [DownloadableSampleSetLoadingState] = []

    XCTAssertEqual(dubSampleSet.loadingState, .notLoaded)

    dubSampleSet.$downloadProgress
      .sink { newProgress in
        progressValues.append(newProgress)
        observedLoadingStates.append(dubSampleSet.loadingState)
      }
      .store(in: &cancellables)

    var urlToDataMap: [String: Data] = [:]
    for (remoteUrl, _) in urlPairs {
      urlToDataMap[remoteUrl.absoluteString] = "Mock file \(remoteUrl.path)".data(using: .utf8)!
    }
    // Just using one mock response for all the downloads
    let mockResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/file")!,
      statusCode: 200,
      httpVersion: "1.1",
      headerFields: nil
    )!
    let mockLoader = MockURLSessionProgressDataLoader(
      urlToDataMap: urlToDataMap,
      mockResponse: mockResponse
    )
    FileDownloadManager.shared = FileDownloadManager(urlSessionDataLoader: mockLoader)

    // The SampleSet local directory does not exist initially
    XCTAssertFalse(fileManager.fileExists(atPath: dubSampleSet.baseSampleSetLocalURL.path))

    await dubSampleSet.downloadSampleSet()

    // The SampleSet local directory now exits
    XCTAssertTrue(fileManager.fileExists(atPath: dubSampleSet.baseSampleSetLocalURL.path))

    XCTAssertEqual(dubSampleSet.loadingState, .loaded)

    // Progress was reported and is always increasing
    XCTAssertTrue(progressValues.isNotEmpty)
    var maxProgressSeen: Double = 0
    for progress in progressValues {
      XCTAssertGreaterThanOrEqual(progress, maxProgressSeen)
      maxProgressSeen = progress
    }
    XCTAssertEqual(maxProgressSeen, 1.0)
    XCTAssertTrue(observedLoadingStates.contains(.loading))
  }
}

extension DownloadableSampleSetTests {
  private func getDownloadableSampleSetFromMockSampleSetIndex() throws -> DownloadableSampleSet {
    let expectation = self.expectation(
      description: "Waiting for remoteSampleSetIndexLoadingState to change"
    )

    store.$remoteSampleSetIndexLoadingState
      .sink { newState in
        if newState == .loaded || newState == .error {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    store.loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
    wait(for: [expectation], timeout: 1.0)

    store.loadRemoteSampleSetIndex()
    let sampleSets = try XCTUnwrap(store.downloadableSampleSets)

    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(
      sampleSets.first { $0.remoteSampleSet.name == "Dub"
      })
    return dubSampleSet
  }

  /// Copies the contents of a source directory to a target directory.
  /// - Parameters:
  ///   - sourceURL: The URL of the source directory.
  ///   - targetURL: The URL of the target directory.
  /// - Throws: An error if the copy operation fails.
  func copyDirectoryContents(from sourceURL: URL, to targetURL: URL) throws {
    let fileManager = FileManager.default

    // Ensure the source directory exists
    guard fileManager.fileExists(atPath: sourceURL.path) else {
      throw NSError(
        domain: "CopyDirectoryError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Source directory does not exist"])
    }

    // Create the target directory if it doesn't exist
    if !fileManager.fileExists(atPath: targetURL.path) {
      try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
    }

    // Get the contents of the source directory
    let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)

    for item in contents {
      let destinationURL = targetURL.appendingPathComponent(item.lastPathComponent)
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }
      try fileManager.copyItem(at: item, to: destinationURL)
    }
  }
}
