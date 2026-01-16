//
//  URLSessionLoading.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/27/24.
//

import Foundation

protocol URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}


class URLSessionLoader: URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    URLSession.shared
      .dataTask(with: urlRequest, completionHandler: completionHandler)
      .resume()
  }
}

class MockURLSessionLoader: URLSessionLoading {
  let mockData: Data?
  let mockResponse: URLResponse
  let mockError: Error?
  var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
  var lastFetchURLRequest: URLRequest?

  convenience init(mockDataUrl: URL, mockResponse: URLResponse, mockError: Error?) {
    let unstructuredData = try! Data(contentsOf: mockDataUrl)
    self.init(mockData: unstructuredData, mockResponse: mockResponse, mockError: mockError)
  }

  init(mockData: Data?, mockResponse: URLResponse, mockError: Error?) {
    self.mockData = mockData
    self.mockResponse = mockResponse
    self.mockError = mockError
  }

  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    self.lastFetchURLRequest = urlRequest
    self.completionHandler = completionHandler
  }

  func resolveCompletionHandler() {
    if let completionHandler = completionHandler {
      completionHandler(mockData, mockResponse, mockError)
    }
  }
}
