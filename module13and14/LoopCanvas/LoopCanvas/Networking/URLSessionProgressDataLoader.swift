//
//  Untitled.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/28/24.
//

import Foundation

protocol URLSessionProgressDataLoading {
  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse)
}


class URLSessionProgressDataLoader: URLSessionProgressDataLoading {
  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse) {
    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

    let contentLength = response.expectedContentLength
    var downloadedData = Data()
    var downloadedBytes: Int64 = 0
    for try await byte in asyncBytes {
      downloadedData.append(byte)
      downloadedBytes += 1
      let downloadedPercentage = Double(downloadedBytes) / Double(contentLength)
      if downloadedBytes % 10000 == 0 {
        progressHandler(downloadedPercentage)
      }
    }

    return (downloadedData, response)
  }
}


class MockURLSessionProgressDataLoader: URLSessionProgressDataLoading {
  var urlToDataMap: [String: Data]
  var mockResponse: URLResponse
  var simulateError: Error?

  init(urlToDataMap: [String: Data], mockResponse: URLResponse, simulateError: Error? = nil) {
    self.urlToDataMap = urlToDataMap
    self.mockResponse = mockResponse
    self.simulateError = simulateError
  }

  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse) {
    if let error = simulateError {
      throw error
    }

    guard let urlString = request.url?.absoluteString,
      let data = urlToDataMap[urlString] else {
      throw URLError(.fileDoesNotExist)
    }

    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(0.0)
    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(0.5)
    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(1.0)

    return (data, self.mockResponse)
  }
}
