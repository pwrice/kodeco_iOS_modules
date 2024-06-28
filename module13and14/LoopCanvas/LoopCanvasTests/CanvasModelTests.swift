//
//  CanvasModelTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 6/11/24.
//
import SwiftUI

import XCTest

final class CanvasModelTests: XCTestCase {
  var canvasModel: CanvasModel!
  var musicEngine: MockMusicEngine!

  override func setUpWithError() throws {
    musicEngine = MockMusicEngine()
    canvasModel = CanvasModel(musicEngine: musicEngine)
    canvasModel = CanvasModel()
  }

  func testEmptyState() throws {
    XCTAssertEqual(canvasModel.blocksGroups.count, 0)
    XCTAssertNotNil(canvasModel.library)
  }

  func testAddBlockGroup() throws {
    let block = getFirstTestBlock()

    canvasModel.addBlockGroup(initialBlock: block)

    XCTAssertEqual(canvasModel.blocksGroups.count, 1)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    XCTAssertEqual(blockGroup.allBlocks.first, block)
  }

  func testAddBlockToExistingGroup() throws {
    let firstBlock = getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)

    let nextBlock = getSecondTestBlock()

    let slot = SlotPostion.right.getSlot(relativeTo: firstBlock.location)
    XCTAssertEqual(slot.gridPosX, 1)
    XCTAssertEqual(slot.gridPosY, 0)
    XCTAssertEqual(slot.location, CGPoint(
      x: firstBlock.location.x + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
      y: firstBlock.location.y))

    canvasModel.addBlockToExistingBlockGroup(blockGroup: blockGroup, block: nextBlock, slot: slot)

    XCTAssertEqual(canvasModel.blocksGroups.count, 1)
    XCTAssertEqual(blockGroup.allBlocks.count, 2)
    let seconcBlock = blockGroup.allBlocks[1]

    XCTAssertEqual(seconcBlock.id, nextBlock.id)
    XCTAssertEqual(seconcBlock.location, slot.location)
    XCTAssertEqual(seconcBlock.blockGroupGridPosX, slot.gridPosX)
    XCTAssertEqual(seconcBlock.blockGroupGridPosY, slot.gridPosY)
  }

  func testFindEligibleSlotForBlock_FarAway() throws {
    let firstBlock = getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)

    let nextBlock = getSecondTestBlock()
    nextBlock.location = CGPoint(x: 1000, y: 1000)

    XCTAssertNil(canvasModel.findEligibleSlotForBlock(block: nextBlock))
  }

  func testFindEligibleSlotForBlock_RightSlot() throws {
    let firstBlock = getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)

    let nextBlock = getSecondTestBlock()
    let slot = SlotPostion.right.getSlot(relativeTo: firstBlock.location)
    nextBlock.location = slot.location

    let (foundGroup, foundSlot) = try XCTUnwrap(canvasModel.findEligibleSlotForBlock(block: nextBlock))
    XCTAssertEqual(foundGroup.id, blockGroup.id)
    XCTAssertEqual(foundSlot.location, CGPoint(
      x: firstBlock.location.x + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
      y: firstBlock.location.y))
    XCTAssertEqual(foundSlot.gridPosX, 1)
    XCTAssertEqual(foundSlot.gridPosY, 0)
  }


  func testRemoveBlockFromBlockGroup() throws {
    let firstBlock = getFirstTestBlock()
    let nextBlock = getSecondTestBlock()
    let slot = BlockGroupSlot(
      gridPosX: 1,
      gridPosY: 0,
      location: CGPoint(
        x: firstBlock.location.x + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
        y: firstBlock.location.y)
    )

    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    canvasModel.addBlockToExistingBlockGroup(blockGroup: blockGroup, block: nextBlock, slot: slot)

    canvasModel.removeBlockFromBlockGroup(block: firstBlock, blockGroup: blockGroup)

    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    let remainingBlock = try XCTUnwrap(blockGroup.allBlocks.first)
    XCTAssertEqual(remainingBlock.id, nextBlock.id)
  }

  func testRemoveLastBlockFromBlockGroup() throws {
    let firstBlock = getFirstTestBlock()

    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    canvasModel.removeBlockFromBlockGroup(block: firstBlock, blockGroup: blockGroup)

    XCTAssertEqual(canvasModel.blocksGroups.count, 0)
  }

  func getFirstTestBlock() -> Block {
    return Block(
      id: 0,
      location: CGPoint(x: 0, y: 0),
      color: .pink,
      icon: "square",
      loopURL: URL(fileURLWithPath: "TEST_FILE.wav", relativeTo: Bundle.main.bundleURL)
    )
  }

  func getSecondTestBlock() -> Block {
    return Block(
      id: 1,
      location: CGPoint(x: 100, y: 100),
      color: .blue,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "TEST_FILE_1.wav", relativeTo: Bundle.main.bundleURL)
    )
  }
}
