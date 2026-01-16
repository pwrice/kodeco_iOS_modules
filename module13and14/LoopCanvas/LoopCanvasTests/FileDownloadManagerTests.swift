//
//  FileDownloadManagerTests.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/28/24.
//

import XCTest

class FileDownloadManagerTests: XCTestCase {
  var mockLoader: MockURLSessionProgressDataLoader!
  var fileDownloadManager: FileDownloadManager!
  let testDirectory = FileManager.default.temporaryDirectory.appending(path: "FileDownloadManagerTests")
  var fileURL: URL!

  override func setUpWithError() throws {
    let mockData = "Mock file content".data(using: .utf8)!
    fileURL = URL(string: "https://example.com/file")
    let mockResponse = HTTPURLResponse(
      url: URL(string: "https://example.com/file")!,
      statusCode: 200,
      httpVersion: "1.1",
      headerFields: nil
    )!

    // Make sure we have a clean test directory
    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: testDirectory.path) {
        try fileManager.removeItem(at: testDirectory)
      }
      try fileManager.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    mockLoader = MockURLSessionProgressDataLoader(
      urlToDataMap: [fileURL.absoluteString: mockData],
      mockResponse: mockResponse
    )

    fileDownloadManager = FileDownloadManager(urlSessionDataLoader: mockLoader)
  }

  func testDownloadFiles_SuccessfulDownload() async throws {
    // Prepare URLs
    let destinationFolder = testDirectory

    // Track progress
    var progressValues: [Double] = []
    let testProgressHandler: (Double) -> Void = { progress in
      progressValues.append(progress)
    }

    // Perform download
    let result = try await fileDownloadManager.downloadFiles(
      from: [fileURL], to: [destinationFolder], progressHandler: testProgressHandler)

    // Verify downloaded file exists
    let destinationFile = try XCTUnwrap(result[fileURL])
    XCTAssertTrue(FileManager.default.fileExists(atPath: destinationFile.path))

    // Verify file content
    let content = try String(contentsOf: destinationFile)
    XCTAssertEqual(content, "Mock file content")

    // Verify progress updates
    XCTAssertFalse(progressValues.isEmpty, "Progress should have been reported.")
    XCTAssertEqual(progressValues.last, 1.0, "Progress should reach 100%.")
  }

  func testDownloadFiles_ErrorHandling() async throws {
    // Inject error
    mockLoader.simulateError = URLError(.badServerResponse)

    let destinationFolder = testDirectory

    var progressValues: [Double] = []
    let testProgressHandler: (Double) -> Void = { progress in
      progressValues.append(progress)
    }

    do {
      _ = try await fileDownloadManager.downloadFiles(
        from: [fileURL], to: [destinationFolder], progressHandler: testProgressHandler)
      XCTFail("Expected error was not thrown")
    } catch {
      XCTAssertTrue(error is URLError, "Expected URLError to be thrown")
    }
  }
}
