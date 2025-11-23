//
//  CanvasViewModel_BlockGroupEvents.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/22/25.
//

import Foundation
import SwiftUI
import os

extension CanvasViewModel {
  func selectBlockGroup(group: BlockGroup) {
    // Unselect any previously selected group
    if let prev = selectedBlockGroup, prev.id != group.id {
      unselectBlockGroup(group: prev)
    }
    selectedBlockGroup = group
    group.isSelected = true
    for block in group.allBlocks { block.isSelected = true }
  }

  func unselectCurrentlySelectedBlockGroup() {
    if let group = selectedBlockGroup {
      unselectBlockGroup(group: group)
    }
  }

  func unselectBlockGroup(group: BlockGroup) {
    if selectedBlockGroup?.id == group.id { selectedBlockGroup = nil }
    group.isSelected = false
    for block in group.allBlocks { block.isSelected = false }
  }

  func startBlockGroupDrag(blockGroup: BlockGroup) {
    blockGroup.isDragging = true
    canvasVersion += 1
    canvasMessageStore?.startMoveBlockGroup(viewModelId: id, canvasVersion: canvasVersion, blockGroupId: blockGroup.id)
  }

  func updateBlockGroupDragLocation(blockGroup: BlockGroup, location: CGPoint) {
    if !blockGroup.isDragging {
      startBlockGroupDrag(blockGroup: blockGroup)
    }

    // Move the entire group's blocks by the delta from the left-most block anchor
    guard let anchor = blockGroup.leftMostBlock?.location else { return }

    let deltaX = location.x - anchor.x
    let deltaY = location.y - anchor.y

    for block in blockGroup.allBlocks {
      block.location = CGPoint(x: block.location.x + deltaX, y: block.location.y + deltaY)
    }

    updateAllBlocksList()
  }

  @discardableResult
  func dropBlockGroupOnCanvas(blockGroup: BlockGroup) -> BlockGroup {
    blockGroup.isDragging = false

    // Quantize all blocks in the group to the grid on drop, similar to single-block behavior
    withAnimation(.spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.2)) {
      for block in blockGroup.allBlocks {
        let adjusted = CGPoint(
          x: block.location.x - canvasScrollOffset.x,
          y: block.location.y - canvasScrollOffset.y)
        let quantized = CanvasViewModel.quantizedPoint(for: adjusted)
        block.location = quantized
      }
    }

    updateAllBlocksList()

    canvasVersion += 1
    canvasMessageStore?.moveBlockGroup(viewModelId: id, canvasVersion: canvasVersion, blockGroup: blockGroup)

    return blockGroup
  }

  func update(volume: Double, for group: BlockGroup) {
    let clamped = max(0.0, min(1.0, volume))
    group.volume = clamped
    for block in group.allBlocks {
      update(volume: clamped, for: block)
    }
  }

  /// Toggles mute state for all blocks in the given group.
  /// If any block is currently unmuted, mutes all; otherwise, unmutes all.
  func toggleMute(blockGroup group: BlockGroup) {
    let shouldMute = group.allBlocks.contains { !$0.isMuted }
    for block in group.allBlocks where block.isMuted != shouldMute {
      toggleMute(block: block)
    }
  }

  /// Creates a duplicate of all blocks in the group, offset to the right by one grid spacing, and returns the new group.
  @discardableResult
  func duplicate(blockGroup group: BlockGroup) -> BlockGroup? {
    // Compute an offset of one grid spacing in X
    let spacing = CanvasViewModel.gridSpacing()

    // Create copies of each block shifted by spacing
    var newBlocks: [Block] = []
    for block in group.allBlocks {
      let newLocation = CGPoint(x: block.location.x + spacing, y: block.location.y)
      let copy = block.instantiateCopyWith(location: newLocation, isLibraryBlock: false)
      copy.visible = true
      newBlocks.append(copy)
    }

    // Place first block to start a new group
    guard let first = newBlocks.first else { return nil }
    let droppedFirst = dropBlockOnCanvas(block: first)

    // Add remaining blocks to that new or existing group via normal drop logic
    for block in newBlocks.dropFirst() {
      _ = dropBlockOnCanvas(block: block)
    }

    // Find and return the new group (the group containing droppedFirst)
    return droppedFirst.blockGroup
  }

  func delete(blockGroup group: BlockGroup) {
    // Remove all blocks in this group from the canvas
    for block in group.allBlocks { deleteBlockFromCanvas(block: block) }
    updateAllBlocksList()
  }
}
