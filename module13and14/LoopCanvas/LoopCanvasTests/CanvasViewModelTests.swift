//
//  CanvasViewModelTests.swift
//  CanvasViewModel
//
//  Created by Peter Rice on 5/30/24.
//

import XCTest
@testable import LoopCanvas

final class CanvasViewModelTests: XCTestCase {
  var canvasViewModel: CanvasViewModel!
  var musicEngine: MockMusicEngine!
  var canvasStore: CanvasStore!
  var sampleSetStore: SampleSetStore!

  let testBlocks = [
    Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 50, y: 150),
      color: .pink,
      icon: "circle",
      relativePath: "TEST_FILE.wav"),
    Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 150, y: 150),
      color: .purple,
      icon: "square",
      relativePath: "TEST_FILE.wav"),
    Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 250, y: 150),
      color: .indigo,
      icon: "cross",
      relativePath: "TEST_FILE.wav"),
    Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 350, y: 150),
      color: .yellow,
      icon: "diamond",
      relativePath: "TEST_FILE.wav")
  ]

  override func setUpWithError() throws {
    musicEngine = MockMusicEngine()
    sampleSetStore = SampleSetStore()
    canvasStore = CanvasStore(sampleSetStore: sampleSetStore)
    canvasViewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: musicEngine,
      canvasStore: canvasStore,
      sampleSetStore: sampleSetStore)
    canvasViewModel.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    canvasViewModel.updateAllBlocksList()
  }

  func testEmptyCanvasState() throws {
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
    XCTAssertEqual(canvasViewModel.allBlocks.count, 0)
  }

  func testLibraryInitialState() throws {
    XCTAssertEqual(canvasViewModel.canvasModel.library.categories.count, 7)
    let firstCategory = try XCTUnwrap(canvasViewModel.canvasModel.library.categories.first)
    XCTAssertEqual(firstCategory.name, "Bass")
    XCTAssertEqual(firstCategory.blocks.count, 6)
    XCTAssertEqual(firstCategory.color, .pink)
  }

  func testAddFirstBlockToCanvas() throws {
    let blockToAdd = Block(
            id: Block.getNextBlockId(),
            location: CGPoint(x: 50, y: 150),
            color: .pink,
            icon: "circle",
            isLibraryBlock: false
    )

    let addBlockTapPosition = CGPoint(x: 200, y: 400)
    _ = canvasViewModel.addBlockToCanvasOnGrid(
      block: blockToAdd.instantiateCopyWith(
        location: addBlockTapPosition, isLibraryBlock: false))

    // A new block group is created which contains a new block
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)

    // The new block is a clone of the dropped block
    let firstBlock = try XCTUnwrap(newBlockGroup.allBlocks.first)
    XCTAssertNotEqual(firstBlock.id, blockToAdd.id)
    XCTAssertEqual(firstBlock.color, blockToAdd.color)
    XCTAssertEqual(firstBlock.loopURL, blockToAdd.loopURL)
    XCTAssertFalse(firstBlock.isLibraryBlock)
    XCTAssertEqual(firstBlock.relativePath, blockToAdd.relativePath)
    XCTAssertEqual(firstBlock.icon, blockToAdd.icon)

    // The new block is setup properly
    XCTAssertEqual(firstBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(firstBlock.blockGroupGridPosY, 0)

    let gridQuantizedLocation = CanvasViewModel.quantizedPoint(for: addBlockTapPosition)
    XCTAssertEqual(firstBlock.location.x, gridQuantizedLocation.x)
    XCTAssertEqual(firstBlock.location.y, gridQuantizedLocation.y)
  }

  func testDropSecondBlockOnCanvasToConnect() throws {
    // Drop the first block on the canvas
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block below and to the right of the first block,
    // within the slot connecting distance
    let secondBlock = try addBlockToCanvas(
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

  func testDropSecondBlockOnCanvasWithScrollOffset() throws {
    // Drop the first block on the canvas
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Scroll the canvas
    let scrollOffset = CGPoint(x: -500, y: -500)
    canvasViewModel.canvasScrollOffset = scrollOffset

    // Drop second block below and to the right of the first block
    // Note that the coordinates for the drop are offset by the new scroll position
    let secondBlock = try addBlockToCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20 + scrollOffset.x,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20 + scrollOffset.y))

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
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block far to the right of the first block
    let newLocation = CGPoint(
      x: firstBlock.location.x + (3 * CanvasViewModel.blockSize),
      y: firstBlock.location.y - 20)
    let secondBlock = try addBlockToCanvas(libraryBlockIndex: 1, location: newLocation)

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
    let gridQuantizedLocation = CanvasViewModel.quantizedPoint(for: newLocation)
    XCTAssertEqual(secondBlock.location.x, gridQuantizedLocation.x)
    XCTAssertEqual(secondBlock.location.y, gridQuantizedLocation.y)
    XCTAssertEqual(secondBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(secondBlock.blockGroupGridPosY, 0)
  }

  func testDropOnOccupiedSlotDoesNotConnect() throws {
    // Drop the first block on the canvas
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))

    // Drop second block to connect to the first
    let secondBlock = try addBlockToCanvas(
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
    let thirdBlock = try addBlockToCanvas(libraryBlockIndex: 2, location: thirdBlockLocation)

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
    let gridQuantizedLocation = CanvasViewModel.quantizedPoint(for: thirdBlockLocation)
    XCTAssertEqual(thirdBlock.location.x, gridQuantizedLocation.x)
    XCTAssertEqual(thirdBlock.location.y, gridQuantizedLocation.y)
    XCTAssertEqual(thirdBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(thirdBlock.blockGroupGridPosY, 0)
  }

  func testDisconnectBlockOnCanvasToCreateNewGroup() throws {
    // Drop the first block on the canvas
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    // A block group is created
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Drop second block below and to the right of the first block,
    // within the slot connecting distance
    let secondBlock = try addBlockToCanvas(
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
    _ = canvasViewModel.dropBlockOnCanvas(block: secondBlock)

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
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 100, y: 100))
    let secondBlock = try addBlockToCanvas(libraryBlockIndex: 1, location: CGPoint(x: 300, y: 500))

    // We now have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    // Drop third block just below the current first block, overlapping the second block slot
    let thirdBlockLocation = CGPoint(x: firstBlock.location.x, y: firstBlock.location.y + 40)
    let thirdBlock = try addBlockToCanvas(libraryBlockIndex: 2, location: thirdBlockLocation)

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
    _ = canvasViewModel.dropBlockOnCanvas(block: thirdBlock)

    // Now the only the first block is in the first group,
    // and the second block and third blocks are in the second group
    XCTAssertTrue(firstBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(firstBlockGroup.allBlocks.contains(thirdBlock))
    XCTAssertTrue(secondBlockGroup.allBlocks.contains(secondBlock))
    XCTAssertTrue(secondBlockGroup.allBlocks.contains(thirdBlock))
  }

  func testDeleteBlockFromExistingGroup() throws {
    // Drop two blocks on canvas to connect them
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let secondBlock = try addBlockToCanvas(
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

    canvasViewModel.deleteBlockFromCanvas(block: secondBlock)

    // Now the only the first block is in the first group,
    // and the second block is gone
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(blockGroup.allBlocks.contains(secondBlock))
    XCTAssertFalse(canvasViewModel.allBlocks.contains(secondBlock))
  }

  func testDeleteGroup() throws {
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))

    // We have 1 block group and both blocks are members
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let blockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))

    canvasViewModel.deleteBlockFromCanvas(block: firstBlock)

    // Now the block group is gone and the firstBlock nolonger appears on the canvas
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
    XCTAssertFalse(canvasViewModel.allBlocks.contains(firstBlock))
  }

  func testSaveAndLoadSong() throws {
    // Drop two blocks on canvas and connect them
    let origFirstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let origSecondBlock = try addBlockToCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: origFirstBlock.location.x,
        y: origFirstBlock.location.y + CanvasViewModel.blockSize + 40))

    // We have one block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let origBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup.allBlocks.count, 2)
    XCTAssertTrue(origBlockGroup.allBlocks.contains(origFirstBlock))
    XCTAssertTrue(origBlockGroup.allBlocks.contains(origSecondBlock))

    canvasViewModel.canvasModel.name = "TEST_CANVAS"

    canvasViewModel.saveSong()

    // Create a new canvas view model with an empty canvas
    let newCanvasViewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: musicEngine,
      canvasStore: canvasStore,
      sampleSetStore: sampleSetStore
    )
    newCanvasViewModel.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    newCanvasViewModel.updateAllBlocksList()
    XCTAssertEqual(newCanvasViewModel.canvasModel.blocksGroups.count, 0)

    newCanvasViewModel.canvasModel.name = "TEST_CANVAS" // To make sure we load the correct JSON
    newCanvasViewModel.loadSong()

    XCTAssertEqual(newCanvasViewModel.canvasModel.name, "TEST_CANVAS")
    XCTAssertEqual(newCanvasViewModel.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.id, origBlockGroup.id)
    XCTAssertEqual(newBlockGroup.allBlocks.count, origBlockGroup.allBlocks.count)
    let newFirstBlock = try XCTUnwrap(newBlockGroup.allBlocks.first { $0.id == origFirstBlock.id })
    XCTAssertNotNil(newBlockGroup.allBlocks.first { $0.id == origSecondBlock.id })
    XCTAssertEqual(newFirstBlock.color, origFirstBlock.color)
    XCTAssertEqual(newFirstBlock.relativePath, origFirstBlock.relativePath)
    XCTAssertEqual(newFirstBlock.blockGroupGridPosX, origFirstBlock.blockGroupGridPosX)
    XCTAssertEqual(newFirstBlock.blockGroupGridPosY, origFirstBlock.blockGroupGridPosY)
    XCTAssertEqual(newFirstBlock.location, origFirstBlock.location)
  }

  func testLoadSampleSetAndResetCanvas() throws {
    // TODO
  }

  func testGridDimensions_returnsCorrectRowsAndColumns() {
    // Given
    let dotSpacing = CanvasViewModel.blockSize + CanvasViewModel.blockSpacing
    let expectedCols = Int(CanvasViewModel.canvasWidth / dotSpacing)
    let expectedRows = Int(CanvasViewModel.canvasHeight / dotSpacing)

      // When
      let (cols, rows) = CanvasViewModel.gridDimensions()

      // Then
      XCTAssertEqual(cols, expectedCols, "Columns count should match expected calculation")
      XCTAssertEqual(rows, expectedRows, "Rows count should match expected calculation")
  }

  func testGridSpacingIsSumOfBlockSizeAndBlockSpacing() {
    let expected = CanvasViewModel.blockSize + CanvasViewModel.blockSpacing
    XCTAssertEqual(CanvasViewModel.gridSpacing(), expected)
  }


  func testQuantizedPoint() {
    // Given
    // Assume the grid spacing is based on blockSize and blockSpacing.
    // If CanvasViewModel.gridSpacing() = blockSize + blockSpacing,
    // then spacing = 80.0 (70 + 10).
    let spacing = CanvasViewModel.blockSize + CanvasViewModel.blockSpacing
    let halfBlock = (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2.0

    // When
    let input = CGPoint(x: 123.0, y: 77.0)
    let result = CanvasViewModel.quantizedPoint(for: input)

    // Then
    let expectedCol = floor(input.x / spacing)
    let expectedRow = floor(input.y / spacing)
    let expectedX = (expectedCol * spacing) + halfBlock
    let expectedY = (expectedRow * spacing) + halfBlock
    let expected = CGPoint(x: expectedX, y: expectedY)

    XCTAssertEqual(result.x, expected.x, accuracy: 0.001, "Quantized X should match expected grid center")
    XCTAssertEqual(result.y, expected.y, accuracy: 0.001, "Quantized Y should match expected grid center")
  }

  func testQuantizedPointOrigin() {
    let result = CanvasViewModel.quantizedPoint(for: .zero)
    let halfBlock = (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2.0
    XCTAssertEqual(result, CGPoint(x: halfBlock, y: halfBlock), "Origin should quantize to first grid center")
  }
}

// Test Helpers

extension CanvasViewModelTests {
  func addBlockToCanvas(libraryBlockIndex: Int, location: CGPoint) throws -> Block {
    let blockToAdd = testBlocks[libraryBlockIndex]
    let newBlock = canvasViewModel.addBlockToCanvasOnGrid(
      block: blockToAdd.instantiateCopyWith(
        location: location, isLibraryBlock: false))
    return newBlock
  }
}
