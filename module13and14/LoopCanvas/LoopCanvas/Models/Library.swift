//
//  LibraryModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/7/24.
//

import Foundation
import SwiftUI
import os


class Category: ObservableObject, Identifiable {
  let id: Int
  let name: String

  static var colorRange: [Color] = [.pink, .purple, .indigo, .orange, .blue, .cyan, .green]
  var color: Color

  var blocks: [Block]

  init(id: Int, name: String, color: Color, blocks: [Block]) {
    self.id = id
    self.name = name
    self.color = color
    self.blocks = blocks
  }
}

class LibraryData: Codable {
  var name: String

  enum CodingKeys: String, CodingKey {
    case name
  }

  init(name: String) {
    self.name = name
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
  }
}

class Library: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: Library.self)
  )

  @Published var categories: [Category] = []

  var name: String
  var tempo: Double = 120.0

  let maxCategories = 7

  let sampleSetStore: SampleSetStore?

  var data: LibraryData {
    LibraryData(name: name)
  }

  init(sampleSetStore: SampleSetStore?) {
    name = ""
    self.sampleSetStore = sampleSetStore
  }

  init(libraryData: LibraryData, sampleSetStore: SampleSetStore?) {
    name = libraryData.name
    self.sampleSetStore = sampleSetStore
  }

  // Used for previews
  init(categories: [Category], sampleSetStore: SampleSetStore?) {
    name = ""
    self.categories = categories
    self.sampleSetStore = sampleSetStore
  }


  func loadLibraryFrom(libraryFolderName: String) {
    guard let sampleSetStore = sampleSetStore else {
      Self.logger.error("Error: loadLibraryFrom sampleSetStore is nil")
      return
    }

    name = libraryFolderName
    let fileManager = FileManager.default
    let libraryDirectoryURL = URL(
      fileURLWithPath: sampleSetStore.localSamplesDirectory + libraryFolderName,
      relativeTo: Bundle.main.bundleURL)

    do {
      let sampleSetJsonURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: libraryDirectoryURL)
      let decoder = JSONDecoder()
      let sampleSetJSONData = try Data(contentsOf: sampleSetJsonURL)
      let sampleSet = try decoder.decode(LocalSampleSet.self, from: sampleSetJSONData)
      name = sampleSet.name
      tempo = sampleSet.tempo
    } catch {
      Self.logger.error("Error loading library SampleSetInfo.json from JSON \(error)")
    }

    do {
      // Every top level folder is a different category
      let categoryFolders = try fileManager.contentsOfDirectory(atPath: libraryDirectoryURL.path).sorted()
      for (categoryInd, categoryFolderName) in categoryFolders.enumerated()
        where !categoryFolderName.hasSuffix(".json") {
        if categoryInd > maxCategories {
          break
        }
        let categoryDirectoryURL = URL(fileURLWithPath: categoryFolderName, relativeTo: libraryDirectoryURL)
        let categoryColor = Category.colorRange[categoryInd % Category.colorRange.count]
        let cateogryIcons = ["circle", "square", "diamond", "star", "cross", "sun.min", "cloud", "moon"]

        var blocks: [Block] = []
        let sampleFiles = try fileManager.contentsOfDirectory(atPath: categoryDirectoryURL.path).sorted()
        for (sampleInd, sampleFile) in sampleFiles.enumerated() where sampleFile.hasSuffix(".wav") {
          let block = Block(
            id: Block.getNextBlockId(),
            location: CGPoint(x: 100, y: 100),
            color: categoryColor,
            icon: cateogryIcons[sampleInd % cateogryIcons.count],
            loopURL: URL(fileURLWithPath: sampleFile, relativeTo: categoryDirectoryURL),
            relativePath: sampleSetStore.localSamplesDirectory
              + "/" + libraryFolderName + "/" + categoryFolderName + "/" + sampleFile,
            isLibraryBlock: true)
          blocks.append(block)
        }
        let category = Category(id: categoryInd, name: categoryFolderName, color: categoryColor, blocks: blocks)
        categories.append(category)
      }
    } catch {
      Self.logger.error("Error loading library \(libraryFolderName) \(error)")
    }
  }
}
