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

  var imageStore: ImageSearchStore
  var cancellables: [AnyCancellable?] = []

  convenience init(imageStore: ImageSearchStore) {
    self.init(imageStore: imageStore, searchQuery: "")
  }

  init(imageStore: ImageSearchStore, searchQuery: String) {
    self.imageStore = imageStore
    self.searchQuery = searchQuery

    cancellables.append(imageStore.$imageResults.sink { [weak self] imageResults in
      self?.imageResults = imageResults
    })
  }

  public func searchSubmitted() {
    print(">> search submitted: \(searchQuery)")
    imageStore.performNewSearch(query: searchQuery)
  }
}
