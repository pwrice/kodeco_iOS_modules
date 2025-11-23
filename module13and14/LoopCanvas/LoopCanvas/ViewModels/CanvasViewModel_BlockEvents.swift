//
//  CanvasViewModel_BlockEvents.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/22/25.
//

import Foundation
import SwiftUI
import os

extension CanvasViewModel {
  func startBlockDrag(block: Block) {
    block.dragging = true
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    if !block.isLibraryBlock {
      draggingBlock = block
    }
    updateAllBlocksList()

    canvasVersion += 1
    canvasMessageStore?.disconnectBlockFromGroupMessage(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: block)
  }

  func updateBlockDragLocation(block: Block, location: CGPoint) {
    if !block.dragging {
      startBlockDrag(block: block)
    }
    block.location = location
  }

  func addBlockToCanvasOnGrid(newBlock: Block) -> Block {
    addBlockTapGridPosition = nil
    newBlock.location = CanvasViewModel.quantizedPoint(for: CGPoint(
      x: newBlock.location.x - canvasScrollOffset.x,
      y: newBlock.location.y - canvasScrollOffset.y))
    newBlock.visible = true

    let (updatedBlock, newBlockGroup) = dropBlockOnCanvasWithNewGroup(block: newBlock)

    canvasVersion += 1
    canvasMessageStore?.addBlockToCanvasOnGrid(
      viewModelId: id, canvasVersion: canvasVersion, newBlock: updatedBlock, newGroup: newBlockGroup)

    return updatedBlock
  }

  func deleteBlockFromCanvas(block: Block) {
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    updateAllBlocksList()

    canvasVersion += 1
    canvasMessageStore?.deleteBlock(viewModelId: id, canvasVersion: canvasVersion, deletedBlock: block)
  }

  func dropBlockOnCanvas(block: Block) -> Block {
    let (updatedBlock, newBlockGroup) = dropBlockOnCanvasWithNewGroup(block: block)

    // TODO - figure out if this is an existing block and call add if it is new
    canvasVersion += 1
    canvasMessageStore?.moveBlock(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: updatedBlock, newGroup: newBlockGroup)

    return updatedBlock
  }

  func dropBlockOnCanvasWithNewGroup(block: Block) -> (Block, BlockGroup?) {
    let blockWasBeingDragged = block.dragging
    block.dragging = false
    draggingBlock = nil

    var blockDroppedOnCanvas = block
    if block.isLibraryBlock {
      blockDroppedOnCanvas = Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: block.location.x - canvasScrollOffset.x, y: block.location.y - canvasScrollOffset.y),
        color: block.color,
        icon: block.icon,
        visible: true,
        loopURL: block.loopURL,
        relativePath: block.relativePath
      )
    }

    let (_, newBlockGroup) = canvasModel.addBlockToExistingOrNewGroup(block: blockDroppedOnCanvas)

    updateAllBlocksList()

    if blockWasBeingDragged {
      // Animate the block into place
      let adjusted = CGPoint(
        x: blockDroppedOnCanvas.location.x - canvasScrollOffset.x,
        y: blockDroppedOnCanvas.location.y - canvasScrollOffset.y)
      let quantized = CanvasViewModel.quantizedPoint(for: adjusted)
      withAnimation(.spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.2)) {
        blockDroppedOnCanvas.location = quantized
      }
    }

    return (blockDroppedOnCanvas, newBlockGroup)
  }

  func selectBlock(block: Block) {
    selectedBlock = block
    block.isSelected = true
    blockDetailsViewModel = BlockDetailsViewModel(block: block)
  }

  func unselectCurrentlySelectedBlock() {
    if let block = selectedBlock {
      unselectBlock(block: block)
    }
  }

  func unselectBlock(block: Block) {
    selectedBlock = nil
    block.isSelected = false
    blockDetailsViewModel = nil
  }

  func toggleMute(block: Block) {
    block.isMuted.toggle()

    canvasVersion += 1
    canvasMessageStore?.updateBlockIsMuted(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: block, isMuted: block.isMuted)
  }

  // New updates for details sheet

  func update(startOffset: Int, for block: Block) {
    block.blockGroup?.updateBlockStartOffset(block: block, newStartOffset: startOffset)
    canvasVersion += 1
    canvasMessageStore?.updateBlockStartOffset(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: block, startOffset: startOffset)
  }

  func update(volume: Double, for block: Block) {
    let clamped = max(0.0, min(1.0, volume))
    block.volume = clamped
    canvasVersion += 1
    canvasMessageStore?.updateBlockVolume(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: block, volume: clamped)
  }

  func update(numBars: Int, for block: Block) {
    block.blockGroup?.updateBlockNumBars(block: block, newNumBars: numBars)
    canvasVersion += 1
    canvasMessageStore?.updateBlockNumBars(
      viewModelId: id, canvasVersion: canvasVersion, updatedBlock: block, numBars: numBars)
  }

  /// Decrement the number of bars for a block by 1 with clamping to [1, block.maxNumBars]
  func decrementNumBars(for block: Block) {
    update(numBars: block.numBars - 1, for: block)
  }

  /// Increment the number of bars for a block by 1 with clamping to [1, block.maxNumBars]
  func incrementNumBars(for block: Block) {
    update(numBars: block.numBars + 1, for: block)
  }

  /// Decrement the start offset for a block by 1 with clamping to [0, (block.maxNumBars) - 1]
  func decrementStartOffset(for block: Block) {
    update(startOffset: block.startOffset - 1, for: block)
  }

  /// Increment the start offset for a block by 1 with clamping to [0, (block.maxNumBars) - 1]
  func incrementStartOffset(for block: Block) {
    update(startOffset: block.startOffset + 1, for: block)
  }

  @discardableResult
  func duplicate(block: Block) -> Block {
    // TODO - move this logic into CanvasModel

    // Attempt to place to the right by one grid
    let spacing = CanvasViewModel.gridSpacing()
    let newLocation = CGPoint(x: block.location.x + spacing, y: block.location.y)
    let newBlock = block.instantiateCopyWith(location: newLocation, isLibraryBlock: false)
    newBlock.visible = true
    let (updatedBlock, _) = dropBlockOnCanvasWithNewGroup(block: newBlock)

    canvasVersion += 1
    canvasMessageStore?.duplicateBlock(viewModelId: id, canvasVersion: canvasVersion, newBlock: updatedBlock)
    return updatedBlock
  }
}
