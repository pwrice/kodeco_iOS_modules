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

import Foundation

enum JSONDataLoadingStoreDataState {
  case notLoaded
  case loading
  case loaded
  case writing
  case errorLoading
  case errorWriting
}

enum JSONDataLoadingStoreError: Error, Equatable {
  case dataFileNotFound(String)
}

protocol JSONDataLoadingStore: AnyObject {
  associatedtype DataType: Codable
  associatedtype DataContainerType: Codable

  var dataState: JSONDataLoadingStoreDataState { get set }
  var bundleJSONURL: URL { get set }
  var documentsJSONURL: URL { get set }
  var data: DataType? { get set }

  func extractDataFromContainer(_ container: DataContainerType) -> DataType?
  func createContainerFromData(_ data: DataType?) -> DataContainerType
}

extension JSONDataLoadingStore {
  func readJSON() {
    do {
      dataState = .loading
      data = try readJSON(with: bundleJSONURL, fallingBackTo: documentsJSONURL)
      dataState = .loaded
    } catch {
      dataState = .errorLoading
    }
  }

  func readJSONFromUrl(url: URL) throws -> DataType? {
    let decoder = JSONDecoder()
    do {
      let unstructuredUserData = try Data(contentsOf: url)
      let dataJSONContainer = try decoder.decode(DataContainerType.self, from: unstructuredUserData)
      return extractDataFromContainer(dataJSONContainer)
    } catch {
      throw JSONDataLoadingStoreError.dataFileNotFound("Error loading and parsing file at \(url)")
    }
  }

  func readJSON(with primaryURL: URL, fallingBackTo fallbackURL: URL) throws -> DataType? {
    if FileManager.default.fileExists(atPath: primaryURL.path) {
      return try readJSONFromUrl(url: primaryURL)
    } else if FileManager.default.fileExists(atPath: fallbackURL.path) {
      return try readJSONFromUrl(url: fallbackURL)
    } else {
      throw JSONDataLoadingStoreError.dataFileNotFound(
        "Api data file not found at primaryURL: \(primaryURL) or \(fallbackURL)")
    }
  }

  func writeJSON() {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
      dataState = .writing
      let dataContainer = createContainerFromData(data)
      let unstructuredUserData = try encoder.encode(dataContainer)
      try unstructuredUserData.write(to: documentsJSONURL, options: .atomicWrite)
      dataState = .loaded
    } catch {
      dataState = .errorWriting
    }
  }
}
