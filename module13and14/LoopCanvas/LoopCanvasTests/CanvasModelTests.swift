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
    canvasModel = CanvasModel(sampleSetStore: SampleSetStore())
    canvasModel.setMusicEngineAfterLoad(musicEngine: musicEngine)
  }

  func testEmptyState() throws {
    XCTAssertEqual(canvasModel.blocksGroups.count, 0)
    XCTAssertNotNil(canvasModel.library)
  }

  func testAddBlockGroup() throws {
    let block = try getFirstTestBlock()

    canvasModel.addBlockGroup(initialBlock: block)

    XCTAssertEqual(canvasModel.blocksGroups.count, 1)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    XCTAssertEqual(blockGroup.allBlocks.first, block)
  }

  func testAddBlockToExistingGroup() throws {
    let firstBlock = try getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)

    let nextBlock = try getSecondTestBlock()

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
    let firstBlock = try getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)

    let nextBlock = try getSecondTestBlock()
    nextBlock.location = CGPoint(x: 1000, y: 1000)

    XCTAssertNil(canvasModel.findEligibleSlotForBlock(block: nextBlock))
  }

  func testFindEligibleSlotForBlock_RightSlot() throws {
    let firstBlock = try getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)

    let nextBlock = try getSecondTestBlock()
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

  func testFindEligibleSlotFor2BarBlock_RightSlot() throws {
    let firstBlock = try getFirstTestBlock()
    firstBlock.numBars = 2
    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)

    let nextBlock = try getSecondTestBlock()
    let slot = SlotPostion.right.getSlot(relativeTo: firstBlock.location, xOffsetMultiple: 1)
    nextBlock.location = slot.location

    let (foundGroup, foundSlot) = try XCTUnwrap(canvasModel.findEligibleSlotForBlock(block: nextBlock))
    XCTAssertEqual(foundGroup.id, blockGroup.id)
    // An extra x offset should be applied to the location
    XCTAssertEqual(foundSlot.location, CGPoint(
      x: firstBlock.location.x +
      (CGFloat(1) * (CanvasViewModel.blockSpacing + CanvasViewModel.blockSize)) +
      CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
      y: firstBlock.location.y))
    XCTAssertEqual(foundSlot.gridPosX, 2)
    XCTAssertEqual(foundSlot.gridPosY, 0)
  }

  func testRemoveBlockFromBlockGroup() throws {
    let firstBlock = try getFirstTestBlock()
    let nextBlock = try getSecondTestBlock()
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
    let firstBlock = try getFirstTestBlock()

    canvasModel.addBlockGroup(initialBlock: firstBlock)
    let blockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    canvasModel.removeBlockFromBlockGroup(block: firstBlock, blockGroup: blockGroup)

    XCTAssertEqual(canvasModel.blocksGroups.count, 0)
  }

  func getFirstTestBlock() throws -> Block {
    let id0 = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    return Block(
      id: id0,
      location: CGPoint(x: 0, y: 0),
      color: .pink,
      icon: "square",
      loopURL: URL(fileURLWithPath: "TEST_FILE.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "TEST_FILE.wav"
    )
  }

  func getSecondTestBlock() throws -> Block {
    let id1 = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    return Block(
      id: id1,
      location: CGPoint(x: 100, y: 100),
      color: .blue,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "TEST_FILE_1.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "TEST_FILE_1.wav"
    )
  }
}
