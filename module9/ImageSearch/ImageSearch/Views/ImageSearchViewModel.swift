//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/1/24.
//

import Foundation
import Combine

enum DetailsImageLoadingState {
  case noImage,
    loadingImage,
    loadedImage,
    error
}


class ImageSearchViewModel: ObservableObject {
  // Getting warnings: Publishing changes from background threads is not allowed; 
  // make sure to publish values from the main thread (via operators like receive(on:))
  // on model updates.
  // Why?

  @Published var searchQuery: String
  @Published var imageResults: [PlexelImage] = []
  @Published var searchLoadingState: SearchLoadingState = .noSearch
  @Published var showMoreImagesButton = false

  @Published var detailImageLoadingState: DetailsImageLoadingState = .noImage
  @Published var detailImageLoadingDownloadProgress: Float = 0.0
  @Published var detailImageLocalURL: URL?

  private var imageStore: ImageSearchStore?
  private var detailsImageDownloader: ImageDownloader?

  private var cancellables: [AnyCancellable?] = []

  convenience init(imageStore: ImageSearchStore) {
    self.init(imageStore: imageStore, searchQuery: "", searchLoadingState: .noSearch)
  }

  init(imageStore: ImageSearchStore?, searchQuery: String, searchLoadingState: SearchLoadingState) {
    self.imageStore = imageStore
    self.searchQuery = searchQuery
    self.searchLoadingState = searchLoadingState

    if let imageStore = self.imageStore {
      cancellables.append(imageStore.$imageResults.sink { [weak self] imageResults in
        DispatchQueue.main.async { [weak self] in
          self?.imageResults = imageResults
          self?.showMoreImagesButton = self?.imageStore?.nextPageURL != nil
        }
      })
      cancellables.append(imageStore.$searchLoadingState.sink { [weak self] loadingState in
        DispatchQueue.main.async { [weak self] in
          self?.searchLoadingState = loadingState
          self?.showMoreImagesButton = loadingState == .loadedSearch
        }
      })
    }

    self.detailsImageDownloader = ImageDownloader()

    if let detailsImageDownloader = self.detailsImageDownloader {
      cancellables.append(detailsImageDownloader.$state.sink { [weak self] loadingState in
        DispatchQueue.main.async { [weak self] in
          switch loadingState {
          case .paused:
            self?.detailImageLoadingState = .loadingImage
          case .downloading:
            self?.detailImageLoadingState = .loadingImage
          case .failed:
            self?.detailImageLoadingState = .error
          case .finished:
            self?.detailImageLocalURL = self?.detailsImageDownloader?.downloadLocation
            self?.detailImageLoadingState = .loadedImage
          case .waiting:
            self?.detailImageLoadingState = .loadingImage
          }
        }
      })
      cancellables.append(detailsImageDownloader.$downloadProgress.sink { [weak self] progress in
        DispatchQueue.main.async { [weak self] in
          self?.detailImageLoadingDownloadProgress = progress
        }
      })
    }
  }

  public func searchInputSubmitted() {
    imageStore?.performNewSearch(query: searchQuery)
  }

  public func moreImagesTapped() {
    imageStore?.performNextPageSearch()
  }

  public func clearSearch() {
    imageStore?.clearSearch()
    searchLoadingState = .noSearch
    showMoreImagesButton = false
  }

  public func imageDetailsViewOnAppear(image: PlexelImage) {
    let imageUrl = URL(string: image.sourceURLs.large2x)

    if let imageUrl = imageUrl, let downloadedFileExists = ImageDownloader.downloadedFileExists(downloadURL: imageUrl) {
      if downloadedFileExists {
        detailImageLoadingState = .loadedImage
        detailImageLoadingDownloadProgress = 1.0
        detailImageLocalURL = ImageDownloader.documentUrlForDownloadUrl(downloadURL: imageUrl)
      } else {
        if detailImageLoadingState == .loadingImage && imageUrl != detailsImageDownloader?.downloadURL {
          detailsImageDownloader?.cancel()
        }
        detailImageLoadingState = .loadingImage
        detailImageLoadingDownloadProgress = 0
        detailImageLocalURL = nil
        detailsImageDownloader?.downloadImage(at: imageUrl)
      }
    }
  }

  public func deleteDownloadedImage(image: PlexelImage) {
    let imageUrl = URL(string: image.sourceURLs.large2x)
    if let imageUrl = imageUrl,
      let downloadedImageURL = ImageDownloader.documentUrlForDownloadUrl(downloadURL: imageUrl) {
      let fileManager = FileManager.default
      if fileManager.fileExists(atPath: downloadedImageURL.path) {
        do {
          try fileManager.removeItem(atPath: downloadedImageURL.path)
        } catch {
          print("error deleting local file")
        }
      }
    }
  }
}
