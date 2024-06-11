//
//  CanvasViewModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation

class CanvasViewModel: ObservableObject {
  let musicEngine: MusicEngine

  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]

  var draggingBlock: Block?

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0


  init(canvasModel: CanvasModel, musicEngine: MusicEngine) {
    self.musicEngine = musicEngine // AudioKitMusicEngine()
    self.canvasModel = canvasModel
    self.allBlocks = []
    self.canvasModel.musicEngine = musicEngine
    musicEngine.delegate = canvasModel

    self.updateAllBlocksList()
  }

  func onViewAppear() {
    canvasModel.library.loadLibraryFrom(libraryFolderName: "DubSet")
    canvasModel.library.syncBlockLocationsWithSlots()
    updateAllBlocksList()

    musicEngine.initializeEngine()
    musicEngine.play()
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
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    draggingBlock = block
    canvasModel.library.removeBlock(block: block)
    updateAllBlocksList()
  }

  func dropBlockOnCanvas(block: Block) {
    // TODO - break this function up and refator logic into Canvas Model

    block.dragging = false
    draggingBlock = nil

    let blockAddedToGroup = canvasModel.checkBlockPositionAndAddToAvailableGroup(block: block)

    if !blockAddedToGroup {
      if block.location.y > canvasModel.library.libaryFrame.minY + CanvasViewModel.blockSize / 2 {
        // If the block is re-dropped on the library, delete it.
        // Right now we dont need to do anything as the block is
        // not a member of a group and has been removed from the library,
        // and draggingBlock = nil so the block should simply disappear.
      } else {
        canvasModel.addBlockGroup(initialBlock: block)
      }
    }


    // regardless, add a new block to the open library slot
    for librarySlotLocation in canvasModel.library.librarySlotLocations {
      let blockInLibarySlot = canvasModel.library.allBlocks.first { maybeBlock in
        maybeBlock.id != block.id && maybeBlock.location == librarySlotLocation
      }
      if blockInLibarySlot == nil {
        canvasModel.library.allBlocks.append(
          Block(
            id: Block.getNextBlockId(),
            location: librarySlotLocation,
            color: block.color,
            visible: true,
            loopURL: block.loopURL
          ))
        break
      }
    }

    updateAllBlocksList()
  }

  func updateAllBlocksList() {
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + canvasModel.library.allBlocks
    + [draggingBlock].compactMap { $0 }
    // TODO - use set to make this unique by block id

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList
  }
}
