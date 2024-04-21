//
//  ImageSearchTests.swift
//  ImageSearchTests
//
//  Created by Peter Rice on 2/28/24.
//

import XCTest
@testable import ImageSearch

final class ImageSearchTests: XCTestCase {
  var mockJSONURL: URL!

  override func setUpWithError() throws {
    mockJSONURL = URL(
      fileURLWithPath: "MockResponse",
      relativeTo: Bundle.main.bundleURL)
      .appendingPathExtension("json")
  }

  func testParsingJsonResponse() throws {
    let decoder = JSONDecoder()
    // Question - had to include MockResponse.json in the main app target for this to work. Why?
    let unstructuredData = try Data(contentsOf: mockJSONURL)
    let imageSearchResponse = try decoder.decode(ImageSearchResponse.self, from: unstructuredData)

    XCTAssertEqual(imageSearchResponse.images.count, 9)
    let image = imageSearchResponse.images.first!

    XCTAssertEqual(image.id, 3573351)
    XCTAssertEqual(image.width, 3066)
    XCTAssertEqual(image.height, 3968)
    XCTAssertEqual(image.url, "https://www.pexels.com/photo/trees-during-day-3573351/")
    XCTAssertEqual(image.photographer, "Lukas Rodriguez")
    XCTAssertEqual(image.photographerUrl, "https://www.pexels.com/@lukas-rodriguez-1845331")
    XCTAssertEqual(image.title, "Trees During Day")
    XCTAssertEqual(image.liked, false)
    XCTAssertEqual(image.sourceURLs.original, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png")
    XCTAssertEqual(image.sourceURLs.large2x, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940")
    XCTAssertEqual(image.sourceURLs.large, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&h=650&w=940")
    XCTAssertEqual(image.sourceURLs.medium, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&h=350")
    XCTAssertEqual(image.sourceURLs.small, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&h=130")
    XCTAssertEqual(image.sourceURLs.portrait, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&fit=crop&h=1200&w=800")
    XCTAssertEqual(image.sourceURLs.landscape, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&fit=crop&h=627&w=1200")
    XCTAssertEqual(image.sourceURLs.tiny, "https://images.pexels.com/photos/3573351/pexels-photo-3573351.png?auto=compress&cs=tinysrgb&dpr=1&fit=crop&h=200&w=280")
  }

  // TODO - add test to show that JSON parser gracefully handles missing keys for fields we dont care about

  func testImageStoreInitialState() throws {
    let mockURLSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: HTTPURLResponse(url: mockJSONURL, statusCode: 200, httpVersion: "2.2", headerFields: nil)!,
      mockError: nil)

    let imageSearchStore = ImageSearchStore(
      urlSessionLoader: mockURLSessionLoader,
      apiKeyFileName: "Plexels-Info-Sample")

    XCTAssertEqual(imageSearchStore.searchLoadingState, .noSearch)
    XCTAssertEqual(imageSearchStore.imageResults.count, 0)
    XCTAssertNil(imageSearchStore.totalResults)
    XCTAssertNil(imageSearchStore.currentPage)
    XCTAssertNil(imageSearchStore.nextPageURL)
    XCTAssertEqual(imageSearchStore.plexelsAPIAuthKey, "SAMPLE_API_KEY")
  }

  func testImageStorePerformNewSearch() throws {
    let mockURLSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: HTTPURLResponse(url: mockJSONURL, statusCode: 200, httpVersion: "2.2", headerFields: nil)!,
      mockError: nil)

    let imageSearchStore = ImageSearchStore(
      urlSessionLoader: mockURLSessionLoader,
      apiKeyFileName: "Plexels-Info-Sample")

    imageSearchStore.performNewSearch(query: "cats")

    // Verify that request is formatted properly
    XCTAssertEqual(imageSearchStore.searchLoadingState, .loadingSearch)
    XCTAssertEqual(
      mockURLSessionLoader.lastFetchURLRequest?.url?.absoluteString,
      "https://api.pexels.com/v1/search?query=cats&per_page=10")
    XCTAssertEqual(
      mockURLSessionLoader.lastFetchURLRequest?.httpMethod, "GET")
    XCTAssertEqual(
      mockURLSessionLoader.lastFetchURLRequest?.allHTTPHeaderFields,
      [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "SAMPLE_API_KEY"
      ])

    mockURLSessionLoader.resolveCompletionHandler()

    // Verify state after response
    XCTAssertEqual(imageSearchStore.searchLoadingState, .loadedSearch)
    XCTAssertEqual(imageSearchStore.imageResults.count, 9)
    XCTAssertEqual(imageSearchStore.totalResults, 10000)
    XCTAssertEqual(imageSearchStore.currentPage, 1)
    XCTAssertEqual(imageSearchStore.nextPageURL, URL(string: "https://api.pexels.com/v1/search/?page=2&per_page=9&query=nature"))
  }

  func testImageStorePerformNextPageSearch() throws {
    let mockURLSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: HTTPURLResponse(url: mockJSONURL, statusCode: 200, httpVersion: "2.2", headerFields: nil)!,
      mockError: nil)

    let imageSearchStore = ImageSearchStore(
      urlSessionLoader: mockURLSessionLoader,
      apiKeyFileName: "Plexels-Info-Sample")
    imageSearchStore.performNewSearch(query: "cats")
    mockURLSessionLoader.resolveCompletionHandler()

    // TODO - update w/ next page mock JSON
    imageSearchStore.performNextPageSearch()

    XCTAssertEqual(imageSearchStore.searchLoadingState, .loadingSearch)

    mockURLSessionLoader.resolveCompletionHandler()

    XCTAssertEqual(imageSearchStore.searchLoadingState, .loadedSearch)
    XCTAssertEqual(imageSearchStore.imageResults.count, 18)
    XCTAssertEqual(imageSearchStore.totalResults, 10000)
    XCTAssertEqual(imageSearchStore.currentPage, 1)
    XCTAssertEqual(imageSearchStore.nextPageURL, URL(string: "https://api.pexels.com/v1/search/?page=2&per_page=9&query=nature"))
  }
}
