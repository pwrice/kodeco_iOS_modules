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
      canvasMessageStore: canvasMessageStore)
    canvasViewModel.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    canvasViewModel.updateAllBlocksList()
  }

  func testBlockAddedMessage() throws {
    let blockToAdd = Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 200, y: 400),
      color: .pink,
      icon: "circle",
      isLibraryBlock: false
    )
    let (updatedBlock, blockGroup) = canvasModel.addBlockToExistingOrNewGroup(block: blockToAdd, mutateModel: false)

    let messagesExpectation = self.expectation(
      description: "Waiting canvasMessageStore.messages to update"
    )
    let allBlocksExpectation = self.expectation(
      description: "Waiting canvasViewModel.allBlocks to update"
    )

    XCTAssertEqual(canvasMessageStore.messages.count, 0)

    canvasMessageStore.addBlockToCanvasOnGrid(newBlock: updatedBlock, newGroup: blockGroup)

    canvasMessageStore.$messages
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
}

// Test Helpers

// extension CanvasMessageStoreTests {
//  func addBlockToCanvas(libraryBlockIndex: Int, location: CGPoint) throws -> Block {
//    let blockToAdd = testBlocks[libraryBlockIndex]
//    let newBlock = canvasViewModel.addBlockToCanvasOnGrid(
//      newBlock: blockToAdd.instantiateCopyWith(
//        location: location, isLibraryBlock: false))
//    return newBlock
//  }
// }
