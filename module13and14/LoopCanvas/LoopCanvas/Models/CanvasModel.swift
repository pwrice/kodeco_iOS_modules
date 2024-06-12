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
        let slotLocations = [
          CGPoint( // top
            x: otherBlock.location.x,
            y: otherBlock.location.y - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize),
          CGPoint( // right
            x: otherBlock.location.x + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
            y: otherBlock.location.y),
          CGPoint( // bottom
            x: otherBlock.location.x,
            y: otherBlock.location.y + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize),
          CGPoint( // left
            x: otherBlock.location.x - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize,
            y: otherBlock.location.y)
        ]
        let slotGridPosOffsets: [(Int, Int)] = [
          (0, -1),
          (1, 0),
          (0, 1),
          (-1, 0)
        ]
        var intersectingSlotGridPosOffset: (Int, Int)?
        var intersectingSlotLocation: CGPoint?
        var minDist: CGFloat = 100000000.0
        for (slotLocation, gridPosOffset) in zip(slotLocations, slotGridPosOffsets) {
          let diffX = block.location.x - slotLocation.x
          let diffY = block.location.y - slotLocation.y
          let dist = diffX * diffX + diffY * diffY
          if abs(diffX) < CanvasViewModel.blockSize && abs(diffY) < CanvasViewModel.blockSize && dist < minDist {
            intersectingSlotLocation = slotLocation
            intersectingSlotGridPosOffset = gridPosOffset
            minDist = dist
            break
          }
        }

        var availableSlotLocation: CGPoint? = intersectingSlotLocation
        for otherBlock in allCanvasBlocks where otherBlock.id != block.id {
          if otherBlock.location == availableSlotLocation {
            availableSlotLocation = nil
            break
          }
        }

        // if slot is available, snap block there
        if let availableSlot = availableSlotLocation, let gridPosOffset = intersectingSlotGridPosOffset {
          let otherBlockGridPosX = otherBlock.blockGroupGridPosX ?? 0
          let otherBlockGridPosY = otherBlock.blockGroupGridPosY ?? 0
          let newGridPosX = otherBlockGridPosX + gridPosOffset.0
          let newGridPosY = otherBlockGridPosY + gridPosOffset.1

          return (blockGroup, BlockGroupSlot(gridPosX: newGridPosX, gridPosY: newGridPosY, location: availableSlot))
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
