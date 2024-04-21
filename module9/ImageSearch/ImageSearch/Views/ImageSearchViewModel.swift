//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/1/24.
//

import Foundation
import Combine

class ImageSearchViewModel: ObservableObject {
  @Published var searchQuery: String
  @Published var imageResults: [PlexelImage] = []
  @Published var searchLoadingState: SearchLoadingState = .noSearch

  private var imageStore: ImageSearchStore?
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
        self?.imageResults = imageResults
      })
      cancellables.append(imageStore.$searchLoadingState.sink { [weak self] loadingState in
        self?.searchLoadingState = loadingState
      })
    }
  }

  public func searchSubmitted() {
    imageStore?.performNewSearch(query: searchQuery)
  }
}
