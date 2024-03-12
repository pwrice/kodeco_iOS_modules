//
//  ImageSearchModels.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/5/24.
//

import Foundation


struct ImageSearchResponse: Codable {
  let totalResults: Int
  let page: Int
  let perPage: Int
  let images: [PlexelImage]
  let nextPage: String
  
  enum CodingKeys: String, CodingKey {
    case totalResults = "total_results",
         page,
         perPage = "per_page",
         images = "photos",
         nextPage = "next_page"
  }
}


struct PlexelImage: Codable {
  let id: Int
  let width: Int
  let height: Int
  let url: String
  let photographer: String
  let photographerUrl: String
  let title: String
  let liked: Bool
  let sourceURLs: PlexelImageSourceURLs
  
  enum CodingKeys: String, CodingKey {
    case id,
         width,
         height,
         url,
         photographer,
         photographerUrl = "photographer_url",
         title = "alt",
         liked,
         sourceURLs = "src"
  }
}

struct PlexelImageSourceURLs: Codable {
  let original: String
  let large2x: String
  let large: String
  let medium: String
  let small: String
  let portrait: String
  let landscape: String
  let tiny: String
}

