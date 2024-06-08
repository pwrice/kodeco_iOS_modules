//
//  BlockGroupModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation

class BlockGroup: ObservableObject, Identifiable {
  @Published var id: Int
  var allBlocks: [Block] = []
  var currentBlockGridXIndex = 0
  var isEmpty: Bool {
    allBlocks.isEmpty
  }

  static var blockGroupIdCounter: Int = 0
  static func getNextBlockGroupId() -> Int {
    let id = blockGroupIdCounter
    blockGroupIdCounter += 1
    return id
  }

  init() {
    id = 0
  }

  init(id: Int, block: Block) {
    self.id = id
    block.blockGroupGridPosX = 0
    block.blockGroupGridPosY = 0
    block.blockGroup = self
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
