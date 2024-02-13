/// Copyright (c) 2024 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import XCTest
import SwiftUI
import Combine

final class AppStoreTests: XCTestCase {
  var apiStore: APIStore!
  var cancellables: [AnyCancellable?] = []

  let missingURL = URL(
    fileURLWithPath: "missingFile",
    relativeTo: URL.documentsDirectory)
    .appendingPathExtension("json")
  let missingKeysJsonURL = URL(
    fileURLWithPath: "apilistMissingKeys",
    relativeTo: Bundle.main.bundleURL)
    .appendingPathExtension("json")

  override func setUpWithError() throws {
    let fileName = "apilist"
    let bundleJSONURL = URL(
      fileURLWithPath: fileName,
      relativeTo: Bundle.main.bundleURL)
    .appendingPathExtension("json")

    let documentsJSONURL = URL(
      fileURLWithPath: fileName,
      relativeTo: URL.documentsDirectory)
    .appendingPathExtension("json")

    apiStore = APIStore(bundleJSONURL: bundleJSONURL, documentsJSONURL: documentsJSONURL)
  }

  override func tearDownWithError() throws {
  }

  func readJsonAndWaitForMainActorUpdate(_ apiStore: APIStore) async {
    let apiDataStateExpectation = XCTestExpectation(description: "apiDataState updated")
    cancellables.append(apiStore.$apiDataState
      .sink { dataState in
        if dataState == .errorLoading || dataState == .errorWriting || dataState == .loaded {
          apiDataStateExpectation.fulfill()
        }
      })

    await apiStore.readJSON()

    await fulfillment(of: [apiDataStateExpectation], timeout: 1)
  }

  func testAppStoreInitialState() throws {
    XCTAssertNotNil(apiStore, "appStore should initialize but was nil")
    XCTAssertEqual(apiStore.apiDataList.count, 0, "Initial apiStore.apiDataList should be empty")
    XCTAssertEqual(apiStore.apiDataState, .notLoaded, "Intial apiStore.apiDataState should be .notLoaded")
  }

  func testReadAPIJSONFromUrl() throws {
    let apiData = try apiStore.readJSONFromLocalUrl(url: apiStore.bundleJSONURL) ?? []
    XCTAssertEqual(
      apiData.isEmpty,
      false,
      "apiStore.readJSONFromUrl(url: apiStore.bundleJSONURL) should read non-empty data")
  }

  func testMissingUrl() throws {
    let fileExistsAtMissingPath = FileManager.default.fileExists(atPath: missingURL.path)
    XCTAssertEqual(fileExistsAtMissingPath, false, "No file should exist at missingURL.path")
  }

  func testReadAPIJSONFromPrimaryUrl() throws {
    let apiData = try apiStore.readLocalJSON(with: apiStore.bundleJSONURL, fallingBackTo: missingURL) ?? []
    XCTAssertEqual(apiData.isEmpty, false, "apiStore.readJSON(with:fallingBackTo:) successfully reads from primary url")
  }

  func testReadAPIJSONFromFallbackUrl() throws {
    let apiData = try apiStore.readLocalJSON(with: missingURL, fallingBackTo: apiStore.bundleJSONURL) ?? []
    XCTAssertEqual(
      apiData.isEmpty,
      false,
      "apiStore.readJSON(with:fallingBackTo:) successfully falls back to secondary url when primary url does not exist")
  }

  func testReadAPIJSON() async throws {
    await readJsonAndWaitForMainActorUpdate(apiStore)

    XCTAssertEqual(
      apiStore.apiDataList.isEmpty,
      false,
      "After successful load apiStore.apiDataList should not be empty")
    XCTAssertEqual(
      apiStore.apiDataState,
      .loaded,
      "After successful load, apiStore.apiDataState should be .loaded")
  }

  func testReadAPIJSONSuccessfullyParsesFixtureForFirstItem() async throws {
    await readJsonAndWaitForMainActorUpdate(apiStore)

    let firstAPIDataItem = apiStore.apiDataList.first!
    XCTAssertEqual(
      firstAPIDataItem.name,
      "AdoptAPet",
      "Its name should be 'AdoptAPet'")
    XCTAssertEqual(
      firstAPIDataItem.description,
      "Resource to help get pets adopted",
      "Its description should be 'Resource to help get pets adopted'")
    XCTAssertEqual(firstAPIDataItem.auth, "apiKey", "Its auth should be 'apiKey'")
    XCTAssertEqual(firstAPIDataItem.cors, true, "Its cors should be true")
    XCTAssertEqual(firstAPIDataItem.url, "https://www.adoptapet.com/public/apis/pet_list.html", "It's url should be 'https://www.adoptapet.com/public/apis/pet_list.html'")
    XCTAssertEqual(firstAPIDataItem.category, "Animals", "Its category should be 'Animals")
  }

  func testReadAPIJSONFromFallbackUrlThrowsError() {
    XCTAssertThrowsError(
      try apiStore.readLocalJSON(with: missingURL, fallingBackTo: missingURL),
      "") { error in
        let apiStoreError = error as! JSONDataLoadingStoreError
        XCTAssertEqual(
          apiStoreError,
          JSONDataLoadingStoreError.dataFileNotFound(
            "Api data file not found at primaryURL: \(missingURL) or \(missingURL)"),
          "appStore.readJSON(with:fallingBackTo:) should throw JSONDataLoadingStoreError.dataFileNotFound on missing paths")
    }
  }

  func testWriteAPIJSON() async throws {
    // Cleanup from any previous run
    if FileManager.default.fileExists(atPath: apiStore.documentsJSONURL.path) {
      try FileManager.default.removeItem(at: apiStore.documentsJSONURL)
    }

    await self.readJsonAndWaitForMainActorUpdate(apiStore)

    XCTAssertEqual(
      FileManager.default.fileExists(atPath: apiStore.documentsJSONURL.path),
      false,
      "before writing, the JSON file does not exist in the documents directory")

    apiStore.writeJSON()
    XCTAssertEqual(
      FileManager.default.fileExists(atPath: apiStore.documentsJSONURL.path),
      true,
      "after writing, the file JSON does exist in the documents directopry")

    let writtenApiData = try apiStore.readJSONFromLocalUrl(url: apiStore.documentsJSONURL) ?? []
    XCTAssertEqual(
      writtenApiData.count,
      apiStore.apiDataList.count,
      "The writtenApiData has the same number of items as the appStore.apiDataList")
    for index in apiStore.apiDataList.indices {
      // Testing each item individually to make it easier to catch diffs
      XCTAssertEqual(
        writtenApiData[index],
        apiStore.apiDataList[index],
        "the written apiData item should match the in memory apiData item")
    }
  }

  func testErrorStateReadingAPIJSON() async throws {
    apiStore = APIStore(bundleJSONURL: missingURL, documentsJSONURL: missingURL)

    await self.readJsonAndWaitForMainActorUpdate(apiStore)

    XCTAssertEqual(
      apiStore.apiDataState,
      .errorLoading,
      "Attempting to read from missingURL puts appStore.apiDataState in .errorLoading, found \(apiStore.apiDataState)")
  }

  func testHandlesMissingKeysWhenReadingAPIJSON() async throws {
    apiStore = APIStore(bundleJSONURL: missingKeysJsonURL, documentsJSONURL: missingKeysJsonURL)
    await self.readJsonAndWaitForMainActorUpdate(apiStore)
    let firstAPIDataItem = apiStore.apiDataList.first!
    XCTAssertEqual(firstAPIDataItem.name, "AdoptAPet", "Its name should be 'AdoptAPet'")
    XCTAssertEqual(
      firstAPIDataItem.description,
      "Resource to help get pets adopted",
      "Its description should be 'Resource to help get pets adopted'")
    XCTAssertEqual(firstAPIDataItem.auth, nil, "Its auth should be nil")
    XCTAssertEqual(firstAPIDataItem.cors, nil, "Its cors should be nil")
    XCTAssertEqual(firstAPIDataItem.https, nil, "Its https should be nil")
    XCTAssertEqual(firstAPIDataItem.url, "https://www.adoptapet.com/public/apis/pet_list.html", "It's url should be 'https://www.adoptapet.com/public/apis/pet_list.html'")
    XCTAssertEqual(firstAPIDataItem.category, "Animals", "Its category should be 'Animals")
  }

  func testWriteAPIJSONWithMissingKeys() async throws {
    // Cleanup from any previous run
    if FileManager.default.fileExists(atPath: apiStore.documentsJSONURL.path) {
      try FileManager.default.removeItem(at: apiStore.documentsJSONURL)
    }

    apiStore = APIStore(bundleJSONURL: missingKeysJsonURL, documentsJSONURL: missingKeysJsonURL)
    await self.readJsonAndWaitForMainActorUpdate(apiStore)
    apiStore.writeJSON()
    let writtenApiData = try apiStore.readJSONFromLocalUrl(url: apiStore.documentsJSONURL) ?? []
    for index in apiStore.apiDataList.indices {
      XCTAssertEqual(
        writtenApiData[index],
        apiStore.apiDataList[index],
        "the written apiData item should match the in memory apiData item")
    }
  }

  func testReadRemoteJSON() async throws {
    var mockByteLoader = MockByteLoader(mockLocalJSONURL: URL(
      fileURLWithPath: "apilist",
      relativeTo: Bundle.main.bundleURL)
      .appendingPathExtension("json"))

    let apiData = try await apiStore.readRemoteJSON(
      at: URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=starlight")!,
      byteLoader: mockByteLoader
    ) ?? []

    XCTAssertEqual(
      apiData.isEmpty,
      false,
      "apiStore.readRemoteJSON() should read non-empty data")
    XCTAssertEqual(
      mockByteLoader.loadingProgress,
      100,
      "apiStore.readRemoteJSON() should set the progress binding to 100, found \(mockByteLoader.loadingProgress)")
  }

  func testReadJSONWithRemoteJSONSucceeds() async throws {
    apiStore = APIStore(
      bundleJSONURL: missingURL,
      documentsJSONURL: missingURL,
      remoteJSONURL: URL(string: "https://api.publicapis.org/entries"),
      byteLoader: MockByteLoader(mockLocalJSONURL: URL(
        fileURLWithPath: "apilist",
        relativeTo: Bundle.main.bundleURL)
        .appendingPathExtension("json"))
    )
    XCTAssertEqual(
      apiStore.apiDataState,
      .notLoaded,
      "Initially, apiStore.apiDataState should be .notLoaded, found \(apiStore.apiDataState)")

    await readJsonAndWaitForMainActorUpdate(apiStore)

    XCTAssertEqual(
      apiStore.apiDataList.isEmpty,
      false,
      "apiStore.apiDataList should be non-empty data")
    XCTAssertEqual(
      apiStore.apiDataState,
      .loaded,
      "After successful load, apiStore.apiDataState should be .loaded")
  }

  func testMissingRemoteAndLocalJSONIsError() async throws {
    apiStore = APIStore(
      bundleJSONURL: missingURL,
      documentsJSONURL: missingURL,
      remoteJSONURL: URL(string: "https://api.publicapis.org/entries"),
      byteLoader: MockByteLoader( // Force an error by passing in missingURL
        mockLocalJSONURL: missingURL)
    )
    XCTAssertEqual(
      apiStore.apiDataState,
      .notLoaded,
      "Initially, apiStore.apiDataState should be .notLoaded, found \(apiStore.apiDataState)")

    await readJsonAndWaitForMainActorUpdate(apiStore)

    XCTAssertEqual(
      apiStore.apiDataList.isEmpty,
      true,
      "apiStore.apiDataList should be empty, found \(apiStore.apiDataList.count) items")
    XCTAssertEqual(
      apiStore.apiDataState,
      .errorLoading,
      "After error, apiStore.apiDataState should be .errorLoading, found \(apiStore.apiDataState)")
  }
}
