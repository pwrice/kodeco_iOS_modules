//
//  ImageSearchViewModel.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/1/24.
//

import Foundation

class ImageSearchViewModel: ObservableObject {
  @Published var imageStore: ImageSearchStore
  
  init(imageStore: ImageSearchStore) {
    self.imageStore = imageStore
  }
}
