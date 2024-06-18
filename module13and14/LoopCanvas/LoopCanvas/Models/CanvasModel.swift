//
//  CanvasModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI

class CanvasModel: ObservableObject {
  var musicEngine: MusicEngine?

  @Published var blocksGroups: [BlockGroup] = []
  @Published var library = Library()


  init() {
  }

  init(musicEngine: MusicEngine) {
    self.musicEngine = musicEngine
    musicEngine.delegate = self
  }


  func addBlockGroup(initialBlock: Block) {
    let newBlockGroup = BlockGroup(id: BlockGroup.getNextBlockGroupId(), block: initialBlock, musicEngine: musicEngine)
    blocksGroups.append(newBlockGroup)
  }

  func addBlockToExistingBlockGroup(blockGroup: BlockGroup, block: Block, slot: BlockGroupSlot) {
    block.location = slot.location
    blockGroup.addBlock(
      block: block,
      gridPosX: slot.gridPosX,
      gridPosY: slot.gridPosY)
  }

  func removeBlockGroup(blockGroup: BlockGroup) {
    blockGroup.musicEngine = nil
    blocksGroups.removeAll { $0.id == blockGroup.id }
  }

  func removeBlockFromBlockGroup(block: Block, blockGroup: BlockGroup) {
    // TODO - verify that block is actually in block group
    blockGroup.removeBlock(block: block)
    if blockGroup.allBlocks.isEmpty {
      removeBlockGroup(blockGroup: blockGroup)
    }
  }

  func findEligibleSlotForBlock(block: Block) -> (BlockGroup, BlockGroupSlot)? {
    let allCanvasBlocks = blocksGroups.flatMap { $0.allBlocks }
    for blockGroup in blocksGroups {
      for otherBlock in blockGroup.allBlocks where otherBlock.id != block.id {
        let relativeSlots: [BlockGroupSlot] = [
          SlotPostion.top.getSlot(relativeTo: otherBlock.location),
          SlotPostion.right.getSlot(relativeTo: otherBlock.location),
          SlotPostion.bottom.getSlot(relativeTo: otherBlock.location),
          SlotPostion.left.getSlot(relativeTo: otherBlock.location)
        ]
        var intersectingSlot: BlockGroupSlot?
        var minDist: CGFloat = 100000000.0
        for slot in relativeSlots {
          let diffX = block.location.x - slot.location.x
          let diffY = block.location.y - slot.location.y
          let dist = diffX * diffX + diffY * diffY
          if abs(diffX) < CanvasViewModel.blockSize && abs(diffY) < CanvasViewModel.blockSize && dist < minDist {
            intersectingSlot = slot
            minDist = dist
            break
          }
        }

        var availableSlot: BlockGroupSlot? = intersectingSlot
        for otherBlock in allCanvasBlocks where otherBlock.id != block.id {
          if otherBlock.location == availableSlot?.location {
            availableSlot = nil
            break
          }
        }

        // if slot is available, snap block there
        if let availableSlot = availableSlot {
          let otherBlockGridPosX = otherBlock.blockGroupGridPosX ?? 0
          let otherBlockGridPosY = otherBlock.blockGroupGridPosY ?? 0
          let newGridPosX = otherBlockGridPosX + availableSlot.gridPosX
          let newGridPosY = otherBlockGridPosY + availableSlot.gridPosY

          return (blockGroup, BlockGroupSlot(gridPosX: newGridPosX, gridPosY: newGridPosY, location: availableSlot.location))
        }
      }
    }
    return nil
  }

  func checkBlockPositionAndAddToAvailableGroup(block: Block) -> Bool {
    // Check all slots around all blocks to see if there is a connection
    if let (blockGroup, slot) = findEligibleSlotForBlock(block: block) {
      addBlockToExistingBlockGroup(blockGroup: blockGroup, block: block, slot: slot)
      return true
    }

    return false
  }
}

extension CanvasModel: MusicEngineDelegate {
  func tick(step16: Int) {
    for blocksGroup in blocksGroups {
      blocksGroup.tick(step16: step16)
    }
  }
}
