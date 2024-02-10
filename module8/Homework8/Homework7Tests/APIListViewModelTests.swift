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
import Combine

final class APIListViewModelTests: XCTestCase {
  var apiStore: APIStore!
  var apiListViewModel: APIListViewModel!
  var errorViewCancellable: AnyCancellable?
  var loadingViewCancellable: AnyCancellable?

  override func setUpWithError() throws {
    apiStore = APIStore()
    apiListViewModel = APIListViewModel(apiStore: apiStore)
  }

  func setAPIStoreDataState(apiStore: APIStore, dataState: JSONDataLoadingStoreDataState) async throws {
    let viewModelExpectation = XCTestExpectation(description: "viewmodel updated")
    errorViewCancellable = apiListViewModel.$showingAPIErrorView
      .sink { _ in
        viewModelExpectation.fulfill()
      }
    loadingViewCancellable = apiListViewModel.$showingAPILoadingIndicator
      .sink { _ in
        viewModelExpectation.fulfill()
      }

    apiStore.dataState = dataState

    await fulfillment(of: [viewModelExpectation], timeout: 1)
  }

  func testInitialDefaultState() throws {
    XCTAssertEqual(
      apiListViewModel.showingAPIErrorView,
      false,
      "Initially showingAPIErrorView is false, found \(apiListViewModel.showingAPIErrorView)")
    XCTAssertEqual(
      apiListViewModel.showingAPILoadingIndicator,
      false,
      "Initially showingAPILoadingIndicator is false, found \(apiListViewModel.showingAPILoadingIndicator)")
  }

  func testDataStateNotLoaded() async throws {
    try await setAPIStoreDataState(apiStore: apiStore, dataState: .notLoaded)

    XCTAssertEqual(
      apiListViewModel.showingAPIErrorView,
      false,
      "For dataState .notLoaded showingAPIErrorView is false, found \(apiListViewModel.showingAPIErrorView)")
    XCTAssertEqual(
      apiListViewModel.showingAPILoadingIndicator,
      false,
      "For dataState .notLoaded showingAPILoadingIndicator is false, found \(apiListViewModel.showingAPILoadingIndicator)")
  }

  func testDataStateLoading() async throws {
    try await setAPIStoreDataState(apiStore: apiStore, dataState: .loading)

    XCTAssertEqual(
      apiListViewModel.showingAPIErrorView,
      false,
      "For dataState .loading showingAPIErrorView is false, found \(apiListViewModel.showingAPIErrorView)")
    XCTAssertEqual(
      apiListViewModel.showingAPILoadingIndicator,
      true,
      "For dataState .loading showingAPILoadingIndicator is true, found \(apiListViewModel.showingAPILoadingIndicator)")
  }

  func testDataStateLoaded() async throws {
    try await setAPIStoreDataState(apiStore: apiStore, dataState: .loaded)

    XCTAssertEqual(
      apiListViewModel.showingAPIErrorView,
      false,
      "For dataState .loaded showingAPIErrorView is false, found \(apiListViewModel.showingAPIErrorView)")
    XCTAssertEqual(
      apiListViewModel.showingAPILoadingIndicator,
      false,
      "For dataState .loaded showingAPILoadingIndicator is false, found \(apiListViewModel.showingAPILoadingIndicator)")
  }

  func testDataStateErrorLoading() async throws {
    try await setAPIStoreDataState(apiStore: apiStore, dataState: .errorLoading)

    XCTAssertEqual(
      apiListViewModel.showingAPIErrorView,
      true,
      "For dataState .errorLoading showingAPIErrorView is true, found \(apiListViewModel.showingAPIErrorView)")
    XCTAssertEqual(
      apiListViewModel.showingAPILoadingIndicator,
      false,
      "For dataState .errorLoading showingAPILoadingIndicator is false, found \(apiListViewModel.showingAPILoadingIndicator)")
  }
}
