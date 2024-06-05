//
//  CanvasModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI

class Block: ObservableObject, Identifiable {
  @Published var id: Int
  @Published var location: CGPoint
  @Published var color: Color
  @Published var visible = true
  @Published var dragging = false

  var blockGroupGridPosX: Int?
  var blockGroupGridPosY: Int?
  weak var blockGroup: BlockGroup?

  static var blockIdCounter: Int = 0
  static func getNextBlockId() -> Int {
    let blockId = blockIdCounter
    blockIdCounter += 1
    return blockId
  }

  init(id: Int, index: Int, location: CGPoint, color: Color, visible: Bool = false) {
    self.id = id
    self.location = location
    self.color = color
    self.visible = visible
  }
}

extension Block: Equatable {
  static func == (lhs: Block, rhs: Block) -> Bool {
    lhs.id == rhs.id &&
    lhs.location == rhs.location &&
    lhs.color == rhs.color &&
    lhs.blockGroupGridPosX == rhs.blockGroupGridPosX &&
    lhs.blockGroupGridPosY == rhs.blockGroupGridPosY
  }
}


class BlockGroup: ObservableObject, Identifiable {
  @Published var id: Int
  var allBlocks: [Block] = []
  var currentBlockGridXIndex = 0

  init() {
    id = 0
  }

  init(id: Int, block: Block) {
    self.id = id
    block.blockGroupGridPosX = 0
    block.blockGroupGridPosY = 0
    allBlocks.append(block)
  }

  func addBlock(block: Block, gridPosX: Int, gridPosY: Int) {
    block.blockGroupGridPosX = gridPosX
    block.blockGroupGridPosY = gridPosY
    block.blockGroup = self
    allBlocks.append(block)
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
    block.blockGroupGridPosX = nil
    block.blockGroupGridPosY = nil
    block.blockGroup = nil
  }
}

class BlockLibrary: ObservableObject {
  @Published var blocks: [Block]
  @Published var librarySlotLocations: [CGPoint]


  init() {
    self.blocks = [
      Block(
        id: 0,
        index: Block.getNextBlockId(),
        location: CGPoint(x: 50, y: 150),
        color: .pink),
      Block(
        id: Block.getNextBlockId(),
        index: 1,
        location: CGPoint(x: 150, y: 150),
        color: .purple),
      Block(
        id: Block.getNextBlockId(),
        index: 2,
        location: CGPoint(x: 250, y: 150),
        color: .indigo),
      Block(
        id: Block.getNextBlockId(),
        index: 3,
        location: CGPoint(x: 350, y: 150),
        color: .yellow)
    ]

    self.librarySlotLocations = [
      CGPoint(x: 50, y: 150),
      CGPoint(x: 150, y: 150),
      CGPoint(x: 250, y: 150),
      CGPoint(x: 350, y: 150)
    ]
  }

  init(blocks: [Block]) {
    self.blocks = blocks
    self.librarySlotLocations = blocks.map { $0.location }
  }

  func syncBlockLocationsWithSlots() {
    for (index, location) in librarySlotLocations.enumerated() {
      blocks[index].location = location
      blocks[index].visible = true
    }
  }
}

class CanvasModel: ObservableObject {
  @Published var blocksGroups: [BlockGroup] = []
  @Published var library = BlockLibrary()


  init() {
  }

  func addBlockGroup(initialBlock: Block) {
    blocksGroups.append(BlockGroup(id: blocksGroups.count, block: initialBlock))
  }
}
