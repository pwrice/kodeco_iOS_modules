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

  func addBlockGroup(initialBlock: Block) {
    let newBlockGroup = BlockGroup(id: BlockGroup.getNextBlockGroupId(), block: initialBlock, musicEngine: musicEngine)
    blocksGroups.append(newBlockGroup)
  }
  func removeBlockGroup(blockGroup: BlockGroup) {
    blockGroup.musicEngine = nil
    blocksGroups.removeAll { $0.id == blockGroup.id }
  }

  func removeBlockFromBlockGroup(block: Block, blockGroup: BlockGroup) {
    // TODO - verify that block is actually in block group
    blockGroup.removeBlock(block: block)
    if blockGroup.allBlocks.isEmpty {
      blocksGroups.removeAll { $0.id == blockGroup.id }
    }
  }

  func findEligibleGroupAndGridPosForBlock(block: Block) -> (BlockGroup, (Int, Int), CGPoint)? {
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
        var intersectingSlot: CGPoint?
        var minDist: CGFloat = 100000000.0
        for (slotLocation, gridPosOffset) in zip(slotLocations, slotGridPosOffsets) {
          let diffX = block.location.x - slotLocation.x
          let diffY = block.location.y - slotLocation.y
          let dist = diffX * diffX + diffY * diffY
          if abs(diffX) < CanvasViewModel.blockSize && abs(diffY) < CanvasViewModel.blockSize && dist < minDist {
            intersectingSlot = slotLocation
            intersectingSlotGridPosOffset = gridPosOffset
            minDist = dist
            break
          }
        }

        var availableSlot: CGPoint? = intersectingSlot
        for otherBlock in allCanvasBlocks where otherBlock.id != block.id {
          if otherBlock.location == availableSlot {
            availableSlot = nil
            break
          }
        }

        // if slot is available, snap block there
        if let availableSlot = availableSlot, let gridPosOffset = intersectingSlotGridPosOffset {
          let otherBlockGridPosX = otherBlock.blockGroupGridPosX ?? 0
          let otherBlockGridPosY = otherBlock.blockGroupGridPosY ?? 0
          let newGridPosX = otherBlockGridPosX + gridPosOffset.0
          let newGridPosY = otherBlockGridPosY + gridPosOffset.1

          return (blockGroup, (newGridPosX, newGridPosY), availableSlot)
        }
      }
    }
    return nil
  }

  func checkBlockPositionAndAddToAvailableGroup(block: Block) -> Bool {
    // Check all slots around all blocks to see if there is a connection
    if let (blockGroup, (gridPosX, gridPosY), newLocation) = findEligibleGroupAndGridPosForBlock(block: block) {
      block.location = newLocation
      blockGroup.addBlock(
        block: block,
        gridPosX: gridPosX,
        gridPosY: gridPosY)
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
