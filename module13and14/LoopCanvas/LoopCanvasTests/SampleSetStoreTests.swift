//
//  SampleSetStoreTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 9/21/24.
//

import XCTest
import Combine
@testable import LoopCanvas

final class SampleSetStoreTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func tearDown() {
    cancellables.removeAll()
    super.tearDown()
  }

  func testLoadRemoteSampleSetIndex() throws {
    let expectation = self.expectation(
      description: "Waiting for remoteSampleSetIndexLoadingState to change"
    )
    var observedStates: [RemoteSampleSetIndexLoadingState] = []

    let mockJSONURL = URL(
      fileURLWithPath: "Samples/SampleSetIndex.json",
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(
      url: mockJSONURL,
      statusCode: 200,
      httpVersion: "2.2",
      headerFields: nil
    )!
    let mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    let store = SampleSetStore(urlSessionLoader: mockUrlSessionLoader)

    store.$remoteSampleSetIndexLoadingState
      .sink { newState in
        observedStates.append(newState)
        if newState == .loaded || newState == .error {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    store.loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
    wait(for: [expectation], timeout: 1.0)

    // Validate the observed states
    XCTAssertTrue(observedStates.contains(.loading), "The state should transition to 'loading'")
    XCTAssertTrue(
      observedStates.contains(.loaded) || observedStates.contains(.error),
      "The state should eventually transition to 'loaded' or 'error'")

    let sampleSets = try XCTUnwrap(store.downloadableSampleSets)

    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(
      sampleSets.first { $0.remoteSampleSet.name == "Dub"
      })
    XCTAssertEqual(dubSampleSet.remoteSampleSet.tempo, 80)
  }

  func testLoadLocalSampleSets() throws {
    let store = SampleSetStore()
    store.loadLocalSampleSets()
    let sampleSets = store.localSampleSets
    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Dub" })
    XCTAssertEqual(dubSampleSet.tempo, 80)
    let funkSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Funk" })
    XCTAssertEqual(funkSampleSet.tempo, 115)
  }
}
