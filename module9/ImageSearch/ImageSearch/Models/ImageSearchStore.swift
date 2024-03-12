//
//  ImageStore.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/1/24.
//

import Foundation


enum SearchLoadingState {
  case noSearch,
       loadingSearch,
       loadedSearch,
       error
}

enum ImageLoadingState {
  case noImage,
       loadingImage,
       error
}

enum ImageSearchStoreError: Error, Equatable {
  case apiKeyError(String)
}

class ImageSearchStore: ObservableObject {
  let urlSessionLoader: URLSessionLoading
  let baseSearchURLString = "https://api.pexels.com/v1/search"
  var plexelsAPIAuthKey: String?
  
  //  let imageSearchNURL: URL? = URL(string: "https://api.pexels.com/v1/search?query=nature&per_page=1")
  // curl -H "Authorization: UxSOTkfIHUWkbY2t5xaxqVAH4oMLVgMhMY3W3fD7ckrLawgGUdUZ44cz" \
  //  "https://api.pexels.com/v1/search?query=nature&per_page=1"
  
  
  var searchLoadingState = SearchLoadingState.noSearch
  var currentQuery: String?
  var totalResults: Int?
  var currentPage: Int?
  var imageResults: [PlexelImage]?
  var nextPageURL: URL?
  
  // Public API
  
  convenience init () {
    self.init(urlSessionLoader: URLSessionLoader(), apiKeyFileName: "Plexels-Info")
  }
  
  init (urlSessionLoader: URLSessionLoading, apiKeyFileName: String) {
    self.urlSessionLoader = urlSessionLoader
    self.plexelsAPIAuthKey = loadPlexelsAPIKey(fileName: apiKeyFileName)
    self.resetLocalState()
  }
  
  public func clearSearch() {
    self.resetLocalState()
  }
  
  public func performNewSearch(query: String) {
    resetLocalState()
    
    guard let newSearchURL = getSearchURL(query: query ) else {
      searchLoadingState = .error
      return
    }
    searchLoadingState = .loadingSearch
    currentQuery = query
    
    do {
      let apiRequest = try getPexelsAPIRequest(for: newSearchURL)
      self.urlSessionLoader.fetchDataFromURL(urlRequest: apiRequest)
      { data, response, error in
        self.processSearchFetch(data: data, response: response, error: error)
      }
    } catch {
      searchLoadingState = .error
    }
    
  }
  
  public func performNextPageSearch() {
    guard let nextPageURL = nextPageURL else {
      searchLoadingState = .error
      return
    }
    searchLoadingState = .loadingSearch
    
    do {
      let apiRequest = try getPexelsAPIRequest(for: nextPageURL)
      self.urlSessionLoader.fetchDataFromURL(urlRequest: apiRequest)
      { data, response, error in
        self.processSearchFetch(data: data, response: response, error: error)
      }
    } catch {
      searchLoadingState = .error
    }
    
  }
  
  // Internal Helpers
  
  func loadPlexelsAPIKey(fileName: String) -> String {
    guard let filePath = Bundle.main.path(forResource: fileName, ofType: "plist") else {
      // TODO
      fatalError("loadPlexelsAPIKey: Couldn't find file '\(fileName).plist'.")
    }
    let plist = NSDictionary(contentsOfFile: filePath)
    guard let value = plist?.object(forKey: "API_KEY") as? String else {
      fatalError("Couldn't find key 'API_KEY' in '\(fileName).plist'.")
    }
    return value
  }
  
  func resetLocalState() {
    currentQuery = nil
    totalResults = nil
    currentPage = nil
    imageResults = []
    nextPageURL = nil
  }
  
  func processSearchFetch(data: Data?, response: URLResponse?, error: Error?) {
    if let data = data, let response = response as? HTTPURLResponse {
      print(response.statusCode)
      if response.statusCode != 200 {
        self.searchLoadingState = .error // weak referecnce for self?
      }
      
      do {
        let decoder = JSONDecoder()
        let imageSearchResponse = try decoder.decode(ImageSearchResponse.self, from: data)
        self.updateLocalStateWithSearchResponse(searchResponse: imageSearchResponse) // weak reference for self?
        
      } catch {
        self.searchLoadingState = .error // weak referecnce for self?
      }
    } else {
      print(
        "Contents fetch failed: " +
        "\(error?.localizedDescription ?? "Unknown error")")
      self.searchLoadingState = .error // weak referecnce for self?
    }
  }
  
  func updateLocalStateWithSearchResponse(searchResponse: ImageSearchResponse) {
    imageResults?.append(contentsOf: searchResponse.images)
    totalResults = searchResponse.totalResults
    currentPage = searchResponse.page
    nextPageURL = URL(string: searchResponse.nextPage)
    searchLoadingState = .loadedSearch
    
  }
  
  func getSearchURL(query: String, itemsPerPage: Int = 10) -> URL? {
    var urlComponents = URLComponents(
      string: baseSearchURLString)
    urlComponents?.queryItems = [
      URLQueryItem(
        name: "query", value: query),
      URLQueryItem(
        name: "per_page", value: String(itemsPerPage))
    ]
    return urlComponents?.url
  }
  
  func getPexelsAPIRequest(for url: URL) throws -> URLRequest {
    guard let apiKey = plexelsAPIAuthKey else {
      throw ImageSearchStoreError.apiKeyError(
        "getPexelsAPIRequest plexelsAPIAuthKey not set")
      
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = [
      "Accept": "application/json",
      "Content-type": "application/json",
      "Authorization": apiKey
    ]
    return request
  }
}

// Session Loading Utilities

protocol URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?)->())
}


class URLSessionLoader: URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?)->()) {
    URLSession.shared
      .dataTask(with: urlRequest, completionHandler: completionHandler)
      .resume()
  }
}


class MockURLSessionLoader: URLSessionLoading {
  let mockData: Data?
  let mockResponse: URLResponse
  let mockError: Error?
  var completionHandler: ((Data?, URLResponse?, Error?)->())?
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
  
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?)->()) {
    self.lastFetchURLRequest = urlRequest
    self.completionHandler = completionHandler
  }
  
  func resolveCompletionHandler() {
    if let completionHandler = completionHandler {
      completionHandler(mockData, mockResponse, mockError)
    }
  }
}
