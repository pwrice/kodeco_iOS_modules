//
//  ImageDownloader.swift
//  ImageSearch
//
//  Created by Peter Rice on 4/24/24.
//

import Foundation

// MARK: State
enum ImageDownloadState {
  case paused
  case downloading
  case failed
  case finished
  case waiting
}

class ImageDownloader: NSObject, ObservableObject {
  @Published var downloadProgress: Float = 0
  @Published var state: ImageDownloadState = .waiting
  var downloadLocation: URL?
  var downloadURL: URL?

  private var downloadTask: URLSessionDownloadTask?
  private var resumeData: Data?

  private var session: URLSession!

  override init() {
    super.init()

    let identifier = "com.pwrice.ImageSearch.ImageDownloader"
    let configuration = URLSessionConfiguration.background(withIdentifier: identifier)

    session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }

  func downloadImage(at url: URL) {
    downloadURL = url

    downloadTask = session.downloadTask(with: url)
    downloadTask?.resume()

    state = .downloading
  }

  func cancel() {
    state = .waiting

    downloadTask?.cancel()

    Task {
      await MainActor.run {
        downloadProgress = 0
      }
    }
  }

  func pause() {
    downloadTask?.cancel { data in
      Task {
        await MainActor.run {
          self.resumeData = data

          self.state = .paused
        }
      }
    }
  }

  func resume() {
    guard let resumeData = resumeData else {
      return
    }

    downloadTask = session.downloadTask(withResumeData: resumeData)
    downloadTask?.resume()

    state = .downloading
  }

  static func documentUrlForDownloadUrl(downloadURL: URL?) -> URL? {
    let fileManager = FileManager.default
    guard let documentsPath = fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask).first,
    let lastPathComponent = downloadURL?.lastPathComponent else { return nil }

    let destinationURL = documentsPath.appendingPathComponent(lastPathComponent)

    return destinationURL
  }

  static func downloadedFileExists(downloadURL: URL?) -> Bool? {
    guard let destinationURL = documentUrlForDownloadUrl(downloadURL: downloadURL) else { return nil }
    let fileManager = FileManager.default
    return fileManager.fileExists(atPath: destinationURL.path)
  }
}


extension ImageDownloader: URLSessionDownloadDelegate {
  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    Task {
      await MainActor.run {
        downloadProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
      }
    }
  }

  func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    let fileManager = FileManager.default

    guard let destinationURL = Self.documentUrlForDownloadUrl(downloadURL: downloadURL) else {
      Task {
        await MainActor.run {
          state = .failed
        }
      }
      return
    }

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try fileManager.copyItem(at: location, to: destinationURL)

      Task {
        await MainActor.run {
          downloadLocation = destinationURL

          state = .finished
        }
      }
    } catch {
      Task {
        await MainActor.run {
          state = .failed
        }
      }
    }
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    Task {
      await MainActor.run {
        if let httpResponse = task.response as? HTTPURLResponse,
        httpResponse.statusCode != 200 {
          state = .failed
        }
      }
    }
  }
}
