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
  @Published var libraryBlocks: [Block]

  var draggingBlock: Block?
  var canvasScrollOffset = CGPoint(x: 0, y: 0)

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0

  init(canvasModel: CanvasModel, musicEngine: MusicEngine) {
    self.musicEngine = musicEngine // AudioKitMusicEngine()
    self.canvasModel = canvasModel
    self.allBlocks = []
    self.libraryBlocks = []
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
    if !block.isLibraryBlock {
      draggingBlock = block
    }
    updateAllBlocksList()
  }

  func dropBlockOnCanvas(block: Block) -> Block {
    // TODO - break this function up and refator logic into Canvas Model

    block.dragging = false
    draggingBlock = nil

    var blockDroppedOnCanvas = block
    if block.isLibraryBlock {
      blockDroppedOnCanvas = Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: block.location.x - canvasScrollOffset.x, y: block.location.y - canvasScrollOffset.y),
        color: block.color,
        visible: true,
        loopURL: block.loopURL
      )

      canvasModel.library.syncBlockLocationsWithSlots() // reset library block location      
    }


    let blockAddedToGroup = canvasModel.checkBlockPositionAndAddToAvailableGroup(block: blockDroppedOnCanvas)

    if !blockAddedToGroup {
      if blockDroppedOnCanvas.location.y > canvasModel.library.libaryFrame.minY + CanvasViewModel.blockSize / 2 {
        // If the block is re-dropped on the library, delete it.
        // Right now we dont need to do anything as the block is
        // not a member of a group and has been removed from the library,
        // and draggingBlock = nil so the block should simply disappear.
      } else {
        canvasModel.addBlockGroup(initialBlock: blockDroppedOnCanvas)
      }
    }

    updateAllBlocksList()

    return blockDroppedOnCanvas
  }

  func updateAllBlocksList() {
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + [draggingBlock].compactMap { $0 }

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList

    var newLibraryBlocksList = canvasModel.library.allBlocks
    newLibraryBlocksList.sort { $0.id > $1.id }
    libraryBlocks = newLibraryBlocksList
  }
}
