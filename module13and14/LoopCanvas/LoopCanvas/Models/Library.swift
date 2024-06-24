//
//  LibraryModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/7/24.
//

import Foundation
import SwiftUI


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

class Library: ObservableObject {
  @Published var allBlocks: [Block]
  @Published var librarySlotLocations: [CGPoint]
  @Published var libaryFrame: CGRect
  @Published var currentCategory: Category?
  @Published var categories: [Category] = []


  let maxCategories = 7

  let samplesDirectory = "Samples/"

  init() {
    self.allBlocks = []

    self.librarySlotLocations = [
      CGPoint(x: 50, y: 150),
      CGPoint(x: 150, y: 150),
      CGPoint(x: 250, y: 150),
      CGPoint(x: 350, y: 150),
      CGPoint(x: 50, y: 250),
      CGPoint(x: 150, y: 250),
      CGPoint(x: 250, y: 250),
      CGPoint(x: 350, y: 250)
    ]
    // this will be reset by the geometry reader
    self.libaryFrame = CGRect(x: 0, y: 800, width: 400, height: 200)
  }

  func syncBlockLocationsWithSlots() {
    for (index, location) in librarySlotLocations.enumerated() where index < allBlocks.count {
      allBlocks[index].location = location
      allBlocks[index].visible = true
    }
  }

  func loadTestData() {
    self.categories = []
    self.allBlocks = [
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 50, y: 150),
        color: .pink,
        icon: "circle"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 150, y: 150),
        color: .purple,
        icon: "square"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 250, y: 150),
        color: .indigo,
        icon: "cross"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 350, y: 150),
        color: .yellow,
        icon: "diamond")
    ]
  }

  func setLoopCategory(categoryName: String) {
    if let category = categories.first(where: { $0.name == categoryName }) {
      currentCategory = category
      allBlocks = category.blocks
    }
  }

  func loadLibraryFrom(libraryFolderName: String) {
    let fileManager = FileManager.default
    let libraryDirectoryURL = URL(
      fileURLWithPath: samplesDirectory + libraryFolderName,
      relativeTo: Bundle.main.bundleURL)
    do {
      // Every top level folder is a different category
      let categoryFolders = try fileManager.contentsOfDirectory(atPath: libraryDirectoryURL.path)
      for (categoryInd, categoryFolderName) in categoryFolders.enumerated() {
        if categoryInd > maxCategories {
          break
        }
        let categoryDirectoryURL = URL(fileURLWithPath: categoryFolderName, relativeTo: libraryDirectoryURL)
        let categoryColor = Category.colorRange[categoryInd % Category.colorRange.count]
        let cateogryIcons = ["circle", "square", "diamond", "star", "cross", "sun.min", "cloud", "moon"]

        var blocks: [Block] = []
        let sampleFiles = try fileManager.contentsOfDirectory(atPath: categoryDirectoryURL.path)
        for (sampleInd, sampleFile) in sampleFiles.enumerated() {
          let block = Block(
            id: Block.getNextBlockId(),
            location: CGPoint(x: 0, y: 0),
            color: categoryColor,
            icon: cateogryIcons[sampleInd % cateogryIcons.count],
            loopURL: URL(fileURLWithPath: sampleFile, relativeTo: categoryDirectoryURL),
            isLibraryBlock: true)
          blocks.append(block)
        }
        let category = Category(id: categoryInd, name: categoryFolderName, color: categoryColor, blocks: blocks)
        categories.append(category)
      }
      setLoopCategory(categoryName: "Drums")
    } catch {
      print(error)
    }
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
  }
}
