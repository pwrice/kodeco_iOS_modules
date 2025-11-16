//
//  CanvasMessageStoreTests.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/16/25.
//

import XCTest
import Combine

@testable import LoopCanvas

final class CanvasMessageStoreTests: XCTestCase {
  var canvasModel: CanvasModel!
  var canvasViewModel: CanvasViewModel!
  var musicEngine: MockMusicEngine!
  var canvasStore: CanvasStore!
  var sampleSetStore: SampleSetStore!
  var canvasMessageStore: CanvasMessageStore!
  var cancellables: Set<AnyCancellable> = []

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
    canvasModel = CanvasModel(sampleSetStore: sampleSetStore)
    musicEngine = MockMusicEngine()
    sampleSetStore = SampleSetStore()
    canvasStore = CanvasStore(sampleSetStore: sampleSetStore)
    canvasMessageStore = CanvasMessageStore()
    canvasViewModel = CanvasViewModel(
      canvasModel: canvasModel,
      musicEngine: musicEngine,
      canvasStore: canvasStore,
      sampleSetStore: sampleSetStore,
      canvasMessageStore: canvasMessageStore,
      viewModelId: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000")))
    canvasViewModel.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    canvasViewModel.updateAllBlocksList()
  }

  func testBlockAndGroupAdded() throws {
    let blockToAdd = Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 200, y: 400),
      color: .pink,
      icon: "circle",
      isLibraryBlock: false
    )

    XCTAssertEqual(canvasMessageStore.messages.count, 0)

    let (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()

    let (updatedBlock, blockGroup) = canvasModel.addBlockToExistingOrNewGroup(block: blockToAdd, mutateModel: false)
    canvasMessageStore.addBlockToCanvasOnGrid(
      viewModelId: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")), // this needs to be different
      newBlock: updatedBlock,
      newGroup: blockGroup)

    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    XCTAssertEqual(canvasMessageStore.messages.count, 1)

    // A new block group is created which contains a new block
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)

    // The new block is a clone of the dropped block
    let firstBlock = try XCTUnwrap(newBlockGroup.allBlocks.first)
    XCTAssertEqual(firstBlock.id, blockToAdd.id)
    XCTAssertEqual(firstBlock.color, blockToAdd.color)
    XCTAssertEqual(firstBlock.loopURL, blockToAdd.loopURL)
    XCTAssertFalse(firstBlock.isLibraryBlock)
    XCTAssertEqual(firstBlock.relativePath, blockToAdd.relativePath)
    XCTAssertEqual(firstBlock.icon, blockToAdd.icon)
    XCTAssertEqual(firstBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(firstBlock.blockGroupGridPosY, 0)
    XCTAssertEqual(firstBlock.location.x, blockToAdd.location.x)
    XCTAssertEqual(firstBlock.location.y, blockToAdd.location.y)
  }

  func testMoveExistingBlockToCreateNewGroup() throws {
    // Drop the first block on the canvas
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let origBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)

    // Drop second block below and to the right of the first block,
    // within the slot connecting distance
    let secondBlock = try addBlockToCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // We have 1 block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Sumimuate drag second block away from first block
    let updatedSecondBlock = Block(dto: secondBlock.toDTO())
    updatedSecondBlock.location = CGPoint(
      x: secondBlock.location.x + CanvasViewModel.blockSize * 3,
      y: secondBlock.location.y)
    updatedSecondBlock.blockGroup = nil

    // First verify that the BlockDisconnectedFromGroupMessage was delivered
    var (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()
    let otherViewModelId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    canvasMessageStore?.disconnectBlockFromGroupMessage(
      viewModelId: otherViewModelId,
      updatedBlock: updatedSecondBlock)

    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    XCTAssertEqual(origBlockGroup.allBlocks.count, 1)

    // New expectations to verify that the BlockMovedMessage is delivered
    (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()
    let (updatedBlock, blockGroup) = canvasModel.addBlockToExistingOrNewGroup(
      block: updatedSecondBlock, mutateModel: false)
    // This would be called from CanvasViewModel.dropBlockOnCanvas()
    canvasMessageStore.moveBlock(
      viewModelId: otherViewModelId, // this needs to be different
      updatedBlock: updatedBlock,
      newGroup: blockGroup)

    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    // We now have 2 block groups
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 2)

    XCTAssertEqual(origBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(origBlockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(origBlockGroup.allBlocks.contains(secondBlock))

    // The second block has been added to a new block group
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first { $0.id != origBlockGroup.id })
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(updatedSecondBlock))
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

    // We have 1 block group
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)

    // Send the delete block message
    var (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()
    let deletedSecondBlock = Block(dto: secondBlock.toDTO())
    let otherViewModelId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    canvasMessageStore?.deleteBlock(viewModelId: otherViewModelId, deletedBlock: deletedSecondBlock)

    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    // Now the only the first block is in the first group,
    // and the second block is gone
    XCTAssertTrue(blockGroup.allBlocks.contains(firstBlock))
    XCTAssertFalse(blockGroup.allBlocks.contains(secondBlock))
    XCTAssertFalse(canvasViewModel.allBlocks.contains(secondBlock))

    // Send anther delete block message
    (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()
    let deletedFirstBlock = Block(dto: firstBlock.toDTO())
    canvasMessageStore?.deleteBlock(viewModelId: otherViewModelId, deletedBlock: deletedFirstBlock)

    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    // Now the block group got deleted as well since there was only 1 block left
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
  }

  func testUpdateBlockNumBarsMessage() throws {
    // Arrange: add two connected blocks in one group
    let firstBlock = try addBlockToCanvas(libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    firstBlock.loopPlayer = nil
    firstBlock.defaultMaxNumBars = 2
    let secondBlock = try addBlockToCanvas(
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + CanvasViewModel.blockSize,
        y: firstBlock.location.y))

    // Verify initial state
    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let group = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertTrue(group.allBlocks.contains(firstBlock))
    XCTAssertTrue(group.allBlocks.contains(secondBlock))

    // Capture original positions to validate downstream shifts
    let originalSecondX = try XCTUnwrap(secondBlock.blockGroupGridPosX)
    let originalSecondLocationX = secondBlock.location.x

    // Act: simulate an external VM updating firstBlock numBars to 2
    let (messagesExpectation, allBlocksExpectation) = getMessagesAndAllBlocksExpectations()
    let otherViewModelId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))

    // Recreate a DTO-based copy to simulate the message payload
    let updatedFirstCopy = Block(dto: firstBlock.toDTO())
    updatedFirstCopy.numBars = 2

    // Send the update message
    canvasMessageStore.updateBlockNumBars(
      viewModelId: otherViewModelId,
      updatedBlock: updatedFirstCopy,
      numBars: updatedFirstCopy.numBars)

    // Assert: wait for processing
    wait(for: [allBlocksExpectation, messagesExpectation], timeout: 1.0)

    // The first block's numBars should be updated, and second block should shift right by one bar
    XCTAssertEqual(firstBlock.numBars, 2)

    // Validate second block shifted by +1 in grid X and visually by one bar width
    let expectedGridX = originalSecondX + 1
    XCTAssertEqual(secondBlock.blockGroupGridPosX, expectedGridX)

    let barPixelWidth = CanvasViewModel.blockSpacing + CanvasViewModel.blockSize
    XCTAssertEqual(secondBlock.location.x, originalSecondLocationX + barPixelWidth)
  }
}

// Test Helpers

extension CanvasMessageStoreTests {
  func addBlockToCanvas(libraryBlockIndex: Int, location: CGPoint) throws -> Block {
    let blockToAdd = testBlocks[libraryBlockIndex]
    let newBlock = canvasViewModel.addBlockToCanvasOnGrid(
      newBlock: blockToAdd.instantiateCopyWith(
        location: location, isLibraryBlock: false))
    return newBlock
  }

  func getMessagesAndAllBlocksExpectations() -> (XCTestExpectation, XCTestExpectation) {
    cancellables.forEach { $0.cancel() }

    let messagesExpectation = self.expectation(
      description: "Waiting canvasMessageStore.messages to update"
    )
    let allBlocksExpectation = self.expectation(
      description: "Waiting canvasViewModel.allBlocks to update"
    )
    canvasMessageStore.$messages
      .dropFirst()
      .sink { _ in
        messagesExpectation.fulfill()
      }
      .store(in: &cancellables)

    canvasViewModel.$allBlocks
      .dropFirst()
      .sink { _ in
        allBlocksExpectation.fulfill()
      }
      .store(in: &cancellables)

    return (messagesExpectation, allBlocksExpectation)
  }
}
