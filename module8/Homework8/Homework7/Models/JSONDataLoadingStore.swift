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
import SwiftUI

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
  case remoteJSONUrlCreationFailed
  case remoteJSONDataParseError(String)
  case remoteJSONUrlNotPresent(String)
  case remoteJSONRequestFailed(String)

}

protocol JSONDataLoadingStore: AnyObject {
  associatedtype DataType: Codable
  associatedtype DataContainerType: Codable

  var bundleJSONURL: URL { get set }
  var documentsJSONURL: URL { get set }

  var remoteJSONURL: URL? { get set }
  var byteLoader: ByteLoading? { get set }

  var dataState: JSONDataLoadingStoreDataState { get set }
  var data: DataType? { get set }

  func extractDataFromContainer(_ container: DataContainerType) -> DataType?
  func createContainerFromData(_ data: DataType?) -> DataContainerType
}

extension JSONDataLoadingStore {
  func readJSON(progress: Binding<Float>? = nil) async {
    dataState = .loading
    // First attempt to load from remote URL
    if let remoteJSONURL = remoteJSONURL, let byteLoader = byteLoader {
      do {
        // If dataload is successful, set data state to loaded and return
        data = try await readRemoteJSON(
          at: remoteJSONURL,
          byteLoader: byteLoader,
          progress: progress
        )
        dataState = .loaded
        return
      } catch {
        print("error loading remote url \(remoteJSONURL)")
      }
    }

    do {
      data = try readLocalJSON(with: bundleJSONURL, fallingBackTo: documentsJSONURL)
      dataState = .loaded
      return
    } catch {
      dataState = .errorLoading
      return
    }
  }

  func readJSONFromLocalUrl(url: URL) throws -> DataType? {
    let decoder = JSONDecoder()
    do {
      let unstructuredData = try Data(contentsOf: url)
      let dataJSONContainer = try decoder.decode(DataContainerType.self, from: unstructuredData)
      return extractDataFromContainer(dataJSONContainer)
    } catch {
      throw JSONDataLoadingStoreError.dataFileNotFound("Error loading and parsing file at \(url)")
    }
  }

  func readLocalJSON(with primaryURL: URL, fallingBackTo fallbackURL: URL) throws -> DataType? {
    if FileManager.default.fileExists(atPath: primaryURL.path) {
      return try readJSONFromLocalUrl(url: primaryURL)
    } else if FileManager.default.fileExists(atPath: fallbackURL.path) {
      return try readJSONFromLocalUrl(url: fallbackURL)
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

  func readRemoteJSON(at url: URL, byteLoader: ByteLoading, progress: Binding<Float>?) async throws -> DataType? {
    do {
      let unstructuredData = try await byteLoader.readBytesFromUrl(url: url, progress: progress)

      let decoder = JSONDecoder()
      let dataJSONContainer = try decoder.decode(DataContainerType.self, from: unstructuredData)
      return extractDataFromContainer(dataJSONContainer)
    } catch {
      throw JSONDataLoadingStoreError.remoteJSONDataParseError("Error loading and parsing file at \(url)")
    }
  }
}

protocol ByteLoading {
  func readBytesFromUrl(url: URL, progress: Binding<Float>?) async throws -> Data
}

struct RemoteByteLoader: ByteLoading {
  func readBytesFromUrl(url: URL, progress: Binding<Float>?) async throws -> Data {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)

    let (asyncBytes, response) = try await session.bytes(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw JSONDataLoadingStoreError.remoteJSONRequestFailed(
        "remoteJSONRequestFailed invalid response type \(response) for url \(url)")
    }
    if !(200..<300).contains(httpResponse.statusCode) {
      throw JSONDataLoadingStoreError.remoteJSONRequestFailed(
        "remoteJSONRequestFailed \(httpResponse.statusCode) for url \(url)")
    }

    let contentLength = Float(response.expectedContentLength)
    var unstructuredData = Data(capacity: Int(contentLength))

    for try await byte in asyncBytes {
      unstructuredData.append(byte)

      let currentProgress = contentLength > 0 ? Float(unstructuredData.count) / contentLength : 0.5

      if let progress = progress, Int(progress.wrappedValue * 100) != Int(currentProgress * 100) {
        progress.wrappedValue = currentProgress
      }
    }

    return unstructuredData
  }
}

struct MockByteLoader: ByteLoading {
  let mockLocalJSONURL: URL

  func readBytesFromUrl(url: URL, progress: Binding<Float>?) async throws -> Data {
    do {
      let unstructuredData = try Data(contentsOf: mockLocalJSONURL)
      if let progress = progress {
        progress.wrappedValue = 100
      }
      return unstructuredData
    } catch {
      throw JSONDataLoadingStoreError.dataFileNotFound("Error loading at \(url)")
    }
  }
}
