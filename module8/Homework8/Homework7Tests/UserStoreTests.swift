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

final class UserStoreTests: XCTestCase {
  var userStore: UserStore!
  let missingURL = URL(
    fileURLWithPath: "missingFile",
    relativeTo: URL.documentsDirectory)
    .appendingPathExtension("json")

  override func setUpWithError() throws {
    userStore = UserStore()
  }

  func readJsonAndWaitForMainActorUpdate(_ userStore: UserStore) async {
    let expectation = XCTestExpectation(description: "userData updated")
    userStore.$userData
      .sink { _ in
        expectation.fulfill()
      }

    await userStore.readJSON()

    await fulfillment(of: [expectation], timeout: 1)
  }
  
  func testAppStoreInitialState() throws {
    XCTAssertNotNil(userStore, "userStore should initialize but was nil")
    XCTAssertNil(userStore.userData, "Initial userStore.userData should be nil")
    XCTAssertEqual(userStore.dataState, .notLoaded, "Intial userStore.dataState should be .notLoaded")
  }

  func testReadJSONFromUrl() throws {
    let apiData = try userStore.readJSONFromLocalUrl(url: userStore.bundleJSONURL)
    XCTAssertNotNil(apiData, "userStore.readAPIJSONFromUrl(url: userStore.bundleJSONURL) should read non-nil data")
  }

  func testMissingUrl() throws {
    let fileExistsAtMissingPath = FileManager.default.fileExists(atPath: missingURL.path)
    XCTAssertEqual(fileExistsAtMissingPath, false, "No file should exist at missingURL.path")
  }

  func testReaJSONFromPrimaryUrl() throws {
    let userData = try userStore.readLocalJSON(with: userStore.bundleJSONURL, fallingBackTo: missingURL)
    XCTAssertNotNil(userData, "userStore.readAPIJSON(with:fallingBackTo:) successfully reads from primary url")
  }

  func testReadJSONFromFallbackUrl() throws {
    let userData = try userStore.readLocalJSON(with: missingURL, fallingBackTo: userStore.bundleJSONURL)
    XCTAssertNotNil(
      userData,
      "userStore.readJSON(with:fallingBackTo:) successfully falls back to secondary url when primary url does not exist")
  }

  func testReadUserJSON() async throws {
    await readJsonAndWaitForMainActorUpdate(userStore)
    
    XCTAssertNotNil(
      userStore.data,
      "After successful load userStore.data should not be empty")
    XCTAssertEqual(
      userStore.dataState,
        .loaded,
      "After successful load, userStore.dataState should be .loaded")
  }

  func testReadJSONFromFallbackUrlThrowsError() {
    XCTAssertThrowsError(
      try userStore.readLocalJSON(with: missingURL, fallingBackTo: missingURL),
      "") { error in
        let error = error as! JSONDataLoadingStoreError
        XCTAssertEqual(
          error,
          JSONDataLoadingStoreError.dataFileNotFound(
            "Api data file not found at primaryURL: \(missingURL) or \(missingURL)"),
          "userStore.readJSON(with:fallingBackTo:) should throw JSONDataLoadingStoreError.DataFileNotFound on missing paths \(missingURL)")
    }
  }

  func testWriteAPIJSON() async throws {
    // Cleanup from any previous run
    if FileManager.default.fileExists(atPath: userStore.documentsJSONURL.path) {
      try FileManager.default.removeItem(at: userStore.documentsJSONURL)
    }

    await readJsonAndWaitForMainActorUpdate(userStore)
    XCTAssertEqual(
      FileManager.default.fileExists(atPath: userStore.documentsJSONURL.path),
      false,
      "before writing, the JSON file does not exist in the documents directory")
    userStore.writeJSON()
    XCTAssertEqual(
      FileManager.default.fileExists(atPath: userStore.documentsJSONURL.path),
      true,
      "after writing, the file JSON does exist in the documents directory")
    let writtenData = try userStore.readJSONFromLocalUrl(url: userStore.documentsJSONURL)
    XCTAssertEqual(writtenData, userStore.userData, "the written data should match the in memory data ")
  }

  func testErrorStateReadingUserJSON() async throws {
    userStore = UserStore(bundleJSONURL: missingURL, documentsJSONURL: missingURL)
    await readJsonAndWaitForMainActorUpdate(userStore)
    XCTAssertEqual(
      userStore.dataState,
      .errorLoading,
      "Attempting to read from missingURL puts userStore.dataState in .errorLoading")
  }
}
