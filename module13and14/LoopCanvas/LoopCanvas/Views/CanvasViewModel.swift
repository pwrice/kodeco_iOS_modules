//
//  CanvasViewModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation

class CanvasViewModel: ObservableObject {
  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]

  var draggingBlock: Block?

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0

  init(canvasModel: CanvasModel) {
    self.canvasModel = canvasModel
    self.allBlocks = []
    self.updateAllBlocksList()
  }

  private func updateAllBlocksList() {
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + canvasModel.library.blocks
    + [draggingBlock].compactMap { $0 }
    // TODO - use set to make this unique by block id

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList
  }

  func updateBlockDragLocation(block: Block, location: CGPoint) {
    if !block.dragging {
      startBlockDrag(block: block)
    }
    block.location = location
  }

  func startBlockDrag(block: Block) {
    block.dragging = true
    if let blockGroup = block.blockGroup {
      blockGroup.removeBlock(block: block)
    }
    draggingBlock = block
    updateAllBlocksList()
  }

  func dropBlockOnCanvas(block: Block) {
    // TODO - break this function up and refator logic into Canvas Model

    block.dragging = false
    draggingBlock = nil

    // Check all slots around all blocks to see if there is a connection
    let allCanvasBlocks = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    var blockAddedToGroup = false
    for blockGroup in canvasModel.blocksGroups {
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
          block.location = availableSlot
          let otherBlockGridPosX = otherBlock.blockGroupGridPosX ?? 0
          let otherBlockGridPosY = otherBlock.blockGroupGridPosY ?? 0
          blockGroup.addBlock(
            block: block,
            gridPosX: otherBlockGridPosX + gridPosOffset.0,
            gridPosY: otherBlockGridPosY + gridPosOffset.1)
          blockAddedToGroup = true
          break
        }
      }
    }

    if !blockAddedToGroup {
      canvasModel.addBlockGroup(initialBlock: block)
    }
    canvasModel.library.blocks.removeAll { $0.id == block.id }

    // regardless, add a new block to the open library slot
    for librarySlotLocation in canvasModel.library.librarySlotLocations {
      let blockInLibarySlot = canvasModel.library.blocks.first { maybeBlock in
        maybeBlock.id != block.id && maybeBlock.location == librarySlotLocation
      }
      if blockInLibarySlot == nil {
        canvasModel.library.blocks.append(
          Block(
            id: Block.getNextBlockId(),
            index: 0,
            location: librarySlotLocation,
            color: block.color,
            visible: true
          ))
        break
      }
    }

    updateAllBlocksList()
  }
}
