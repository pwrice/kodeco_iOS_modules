//
//  LoopCanvasTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 5/30/24.
//

import XCTest
@testable import LoopCanvas

final class LoopCanvasTests: XCTestCase {
  var canvasViewModel: CanvasViewModel!
  var musicEngine: MockMusicEngine!

  override func setUpWithError() throws {
    musicEngine = MockMusicEngine()
    canvasViewModel = CanvasViewModel(canvasModel: CanvasModel(), musicEngine: musicEngine)
    canvasViewModel.canvasModel.library.loadLibraryFrom(libraryFolderName: "DubSet")
    canvasViewModel.canvasModel.library.syncBlockLocationsWithSlots()
    canvasViewModel.updateAllBlocksList()
  }

  func testEmptyCanvasState() throws {
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
    XCTAssertEqual(canvasViewModel.allBlocks.count, 4)
    XCTAssertEqual(canvasViewModel.canvasModel.library.allBlocks.count, 4)
  }

  func testLibraryInitialState() throws {
    XCTAssertEqual(canvasViewModel.canvasModel.library.allBlocks.count, 4)
    for libraryBlock in canvasViewModel.canvasModel.library.allBlocks {
      XCTAssertNil(libraryBlock.blockGroupGridPosX)
      XCTAssertNil(libraryBlock.blockGroupGridPosY)
      XCTAssertNotNil(libraryBlock.loopURL)
    }

    XCTAssertEqual(canvasViewModel.canvasModel.library.categories.count, 7)
    let firstCategory = try XCTUnwrap(canvasViewModel.canvasModel.library.categories.first)
    XCTAssertEqual(firstCategory.name, "Perc")
    XCTAssertEqual(firstCategory.blocks.count, 6)
    XCTAssertEqual(firstCategory.color, .pink)
  }

  func testDropFirstBlockOnCanvas() throws {
    let blockToDrag = try XCTUnwrap(canvasViewModel.canvasModel.library.allBlocks.first)

    // Drag the block to 200, 400 on the canvas
    canvasViewModel.updateBlockDragLocation(
      block: blockToDrag, location: CGPoint(x: 200, y: 400))

    // Drop It
    canvasViewModel.dropBlockOnCanvas(block: blockToDrag)

    // A new block group is created which contains the dropped block
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(blockToDrag))

    // The new block is setup properly
    XCTAssertEqual(blockToDrag.blockGroupGridPosX, 0)
    XCTAssertEqual(blockToDrag.blockGroupGridPosY, 0)
    XCTAssertEqual(blockToDrag.location.x, 200)
    XCTAssertEqual(blockToDrag.location.y, 400)

    // The library is replenished w/ another block in the empty slot,
    // which does not contain the dropped block
    XCTAssertEqual(canvasViewModel.canvasModel.library.allBlocks.count, 4)
    XCTAssertFalse(canvasViewModel.canvasModel.library.allBlocks.contains(blockToDrag))
  }

  func testDropSecondBlockOnCanvasToConnect() throws {
    // Drop the first block on the canvas
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block below and to the right of the first block,
    // within the slot connecting distance
    let secondBlock = try dropLibraryBlockOnCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // We still only have 1 block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // The second block snaps into place below the first block
    XCTAssertEqual(secondBlock.location.x, firstBlock.location.x)
    XCTAssertEqual(
      secondBlock.location.y,
      firstBlock.location.y + CanvasViewModel.blockSize + CanvasViewModel.blockSpacing)

    // The second block has been added to the block group

    let blockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 2)
    XCTAssertTrue(blockGroup.allBlocks.contains(secondBlock))

    // The second block has its group-local grid position updated
    XCTAssertEqual(secondBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(secondBlock.blockGroupGridPosY, 1)
  }

  func testDropSecondBlockOnCanvasToCreateNewGroup() throws {
    // Drop the first block on the canvas
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block far to the right of the first block
    let newLocation = CGPoint(
      x: firstBlock.location.x + (3 * CanvasViewModel.blockSize),
      y: firstBlock.location.y - 20)
    let secondBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 1, location: newLocation)

    // We now have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    // The second block has been added to a new block group
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups[1])
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(secondBlock))

    // The second block is not a member of the original block group
    let origBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(origBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(origBlockGroup.allBlocks.contains(secondBlock))

    // The second block retains its original location and its gridPos is set
    XCTAssertEqual(secondBlock.location.x, newLocation.x)
    XCTAssertEqual(secondBlock.location.y, newLocation.y)
    XCTAssertEqual(secondBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(secondBlock.blockGroupGridPosY, 0)
  }

  func testDropOnOccupiedSlotDoesNotConnect() throws {
    // Drop the first block on the canvas
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))

    // Drop second block to connect to the first
    let secondBlock = try dropLibraryBlockOnCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(x: firstBlock.location.x + 20, y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // We still only have 1 block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    // And the second block has spapped into place below the first block
    XCTAssertEqual(secondBlock.location.x, firstBlock.location.x)
    XCTAssertEqual(
      secondBlock.location.y,
      firstBlock.location.y + CanvasViewModel.blockSize + CanvasViewModel.blockSpacing)

    // Drop third block just below the current first block, overlapping the second block slot
    let thirdBlockLocation = CGPoint(x: firstBlock.location.x, y: firstBlock.location.y + 20)
    let thirdBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 2, location: thirdBlockLocation)

    // We now have 2 block groups b/c the slot below the first block was occupied
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    // The third block is not a member of the original block group
    let origBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup.allBlocks.count, 2)
    XCTAssertTrue(origBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertTrue(origBlockGroup.allBlocks.contains(secondBlock))
    XCTAssertFalse(origBlockGroup.allBlocks.contains(thirdBlock))

    // The third block has been added to a new block group
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups[1])
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(thirdBlock))

    // The third block retains its original location and its gridPos is set
    // TODO - perhaps we should animate the block to a location away from the originalBlock group?
    XCTAssertEqual(thirdBlock.location.x, thirdBlockLocation.x)
    XCTAssertEqual(thirdBlock.location.y, thirdBlockLocation.y)
    XCTAssertEqual(thirdBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(thirdBlock.blockGroupGridPosY, 0)
  }

  func testDisconnectBlockOnCanvasToCreateNewGroup() throws {
    // Drop the first block on the canvas
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block below and to the right of the first block,
    // within the slot connecting distance
    let secondBlock = try dropLibraryBlockOnCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // We still only have 1 block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drag second block away from first block
    canvasViewModel.updateBlockDragLocation(
      block: secondBlock,
      location: CGPoint(
        x: secondBlock.location.x + CanvasViewModel.blockSize * 3,
        y: secondBlock.location.y))
    canvasViewModel.dropBlockOnCanvas(block: secondBlock)

    // We now have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    // The second block is nolonger a member of the original block group
    let origBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(origBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(origBlockGroup.allBlocks.contains(secondBlock))

    // The second block has been added to a new block group
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups[1])
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(secondBlock))
  }

  func testDisconnectBlockOnCanvasToAddToExistingGroup() throws {
    // Drop two blocks on different areas of the canvas
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 100, y: 100))
    let secondBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 1, location: CGPoint(x: 300, y: 500))

    // We now have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    // Drop third block just below the current first block, overlapping the second block slot
    let thirdBlockLocation = CGPoint(x: firstBlock.location.x, y: firstBlock.location.y + 20)
    let thirdBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 2, location: thirdBlockLocation)

    // We still have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)
    let firstBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups[0])
    let secondBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups[1])

    // The first and third block are in the first group, the second block is in its own group
    XCTAssertTrue(firstBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertTrue(firstBlockGroup.allBlocks.contains(thirdBlock))
    XCTAssertTrue(secondBlockGroup.allBlocks.contains(secondBlock))
    XCTAssertFalse(secondBlockGroup.allBlocks.contains(thirdBlock))

    // Drag the third block next to the second block
    canvasViewModel.updateBlockDragLocation(
      block: thirdBlock,
      location: CGPoint(x: secondBlock.location.x + 20, y: secondBlock.location.y))
    canvasViewModel.dropBlockOnCanvas(block: thirdBlock)

    // Now the only the first block is in the first group,
    // and the second block and third blocks are in the second group
    XCTAssertTrue(firstBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(firstBlockGroup.allBlocks.contains(thirdBlock))
    XCTAssertTrue(secondBlockGroup.allBlocks.contains(secondBlock))
    XCTAssertTrue(secondBlockGroup.allBlocks.contains(thirdBlock))
  }

  func testDeleteBlockFromExistingGroup() throws {
    // Drop two blocks on canvas to connect them
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let secondBlock = try dropLibraryBlockOnCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // We have 1 block group and both blocks are members
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let blockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 2)
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))
    XCTAssertTrue(blockGroup.allBlocks.contains(secondBlock))

    // Drag the second block down over the library
    canvasViewModel.updateBlockDragLocation(
      block: secondBlock,
      location: CGPoint(
        x: secondBlock.location.x,
        y: canvasViewModel.canvasModel.library.libaryFrame.minY + CanvasViewModel.blockSize + 20))
    canvasViewModel.dropBlockOnCanvas(block: secondBlock)

    // Now the only the first block is in the first group,
    // and the second block is gone
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(blockGroup.allBlocks.contains(secondBlock))
    XCTAssertFalse(canvasViewModel.allBlocks.contains(secondBlock))
  }

  func testDeleteGroup() throws {
    let firstBlock = try dropLibraryBlockOnCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))

    // We have 1 block group and both blocks are members
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let blockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))

    // Drag the second block down over the library
    canvasViewModel.updateBlockDragLocation(
      block: firstBlock,
      location: CGPoint(
        x: firstBlock.location.x,
        y: canvasViewModel.canvasModel.library.libaryFrame.minY + CanvasViewModel.blockSize + 20))
    canvasViewModel.dropBlockOnCanvas(block: firstBlock)

    // Now the block group is gone and the firstBlock nolonger appears on the canvas
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
    XCTAssertFalse(canvasViewModel.allBlocks.contains(firstBlock))
  }

  func dropLibraryBlockOnCanvas(libraryBlockIndex: Int, location: CGPoint) throws -> Block {
    let block = try XCTUnwrap(canvasViewModel.canvasModel.library.allBlocks[libraryBlockIndex])
    canvasViewModel.updateBlockDragLocation(block: block, location: location)
    canvasViewModel.dropBlockOnCanvas(block: block)
    return block
  }
}
