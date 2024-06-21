//
//  LibraryModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/7/24.
//

import Foundation
import SwiftUI


class Category: ObservableObject {
  let name: String

  static var colorRange: [Color] = [.pink, .purple, .indigo, .orange, .blue, .cyan, .green]
  var color: Color

  var blocks: [Block]

  init(name: String, color: Color, blocks: [Block]) {
    self.name = name
    self.color = color
    self.blocks = blocks
  }
}

class Library: ObservableObject {
  @Published var allBlocks: [Block]
  @Published var librarySlotLocations: [CGPoint]
  @Published var libaryFrame: CGRect

  var categories: [Category] = []
  let maxCategories = 7

  let samplesDirectory = "Samples/"

  init() {
    self.allBlocks = []

    self.librarySlotLocations = [
      CGPoint(x: 50, y: 150),
      CGPoint(x: 150, y: 150),
      CGPoint(x: 250, y: 150),
      CGPoint(x: 350, y: 150)
    ]
    // this will be reset by the geometry reader
    self.libaryFrame = CGRect(x: 0, y: 800, width: 400, height: 200)
  }

  func syncBlockLocationsWithSlots() {
    for (index, location) in librarySlotLocations.enumerated() {
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
        color: .pink),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 150, y: 150),
        color: .purple),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 250, y: 150),
        color: .indigo),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 350, y: 150),
        color: .yellow)
    ]
  }

  func loadLibraryFrom(libraryFolderName: String) {
    let fileManager = FileManager.default
    let libraryDirectoryURL = URL(
      fileURLWithPath: samplesDirectory + libraryFolderName,
      relativeTo: Bundle.main.bundleURL)
    do {
      // Every top level folder is a different category
      let categoryFolders = try fileManager.contentsOfDirectory(atPath: libraryDirectoryURL.path)
      for (ind, categoryFolderName) in categoryFolders.enumerated() {
        if ind > maxCategories {
          break
        }
        let categoryDirectoryURL = URL(fileURLWithPath: categoryFolderName, relativeTo: libraryDirectoryURL)
        let categoryColor = Category.colorRange[ind % Category.colorRange.count]
        var blocks: [Block] = []
        let sampleFiles = try fileManager.contentsOfDirectory(atPath: categoryDirectoryURL.path)
        for sampleFile in sampleFiles {
          let block = Block(
            id: Block.getNextBlockId(),
            location: CGPoint(x: 0, y: 0),
            color: categoryColor,
            loopURL: URL(fileURLWithPath: sampleFile, relativeTo: categoryDirectoryURL),
            isLibraryBlock: true
          )
          blocks.append(block)
        }
        let category = Category(name: categoryFolderName, color: categoryColor, blocks: blocks)
        categories.append(category)
      }

      // for now just loading the first block of a few categories
      var categoryBlocksToShow: [Block] = []
      if let drumsCategory = categories.first(where: { $0.name == "Drums" }) {
        categoryBlocksToShow.append(drumsCategory.blocks[0])
      }
      if let keysCategory = categories.first(where: { $0.name == "Bass" }) {
        categoryBlocksToShow.append(keysCategory.blocks[1])
      }
      if let guitarsCategory = categories.first(where: { $0.name == "Guitars" }) {
        categoryBlocksToShow.append(guitarsCategory.blocks[5])
      }
      if let percCategory = categories.first(where: { $0.name == "Perc" }) {
        categoryBlocksToShow.append(percCategory.blocks[0])
      }

      allBlocks = categoryBlocksToShow
    } catch {
      print(error)
    }
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
  }
}
