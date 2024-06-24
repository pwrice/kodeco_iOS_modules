//
//  BlockGroupTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 6/11/24.
//
import SwiftUI
import XCTest

final class BlockGroupTests: XCTestCase {
  var musicEngine: MockMusicEngine!

  override func setUpWithError() throws {
    musicEngine = MockMusicEngine()
    musicEngine.initializeEngine()
  }

  func testInitWithBlock() throws {
    let block = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    let blockGroup = BlockGroup(id: 0, block: block, musicEngine: musicEngine)

    XCTAssertEqual(blockGroup.allBlocks.count, 1)
    XCTAssertEqual(blockGroup.allBlocks.first, block)
    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
  }

  func testNoOpOnTick() throws {
    let block = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    let blockGroup = BlockGroup(id: 0, block: block, musicEngine: musicEngine)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(block.isPlaying, false)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, false)

    let tick = 0
    XCTAssertNotEqual(tick, musicEngine.nextBarLogicTick)
    blockGroup.tick(step16: tick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(block.isPlaying, false)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, false)
  }

  func testTickPlaysSingleBlock() throws {
    let block = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    let blockGroup = BlockGroup(id: 0, block: block, musicEngine: musicEngine)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(block.isPlaying, false)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, false)

    let tick = musicEngine.nextBarLogicTick
    blockGroup.tick(step16: tick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(block.isPlaying, true)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, true)
  }

  func testTickAdvancesPlayToAdjacentBlock() throws {
    let firstBlock = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    let blockGroup = BlockGroup(id: 0, block: firstBlock, musicEngine: musicEngine)

    blockGroup.tick(step16: musicEngine.nextBarLogicTick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(firstBlock.isPlaying, true)
    XCTAssertEqual(firstBlock.loopPlayer?.loopPlaying, true)

    let rightSlot = SlotPostion.right.getSlot(relativeTo: firstBlock)
    let secondBlock = getTestBlock(id: 1, location: rightSlot.location)
    blockGroup.addBlock(block: secondBlock, gridPosX: rightSlot.gridPosX, gridPosY: rightSlot.gridPosY)

    blockGroup.tick(step16: musicEngine.nextBarLogicTick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 1)
    XCTAssertEqual(firstBlock.isPlaying, false)
    XCTAssertEqual(firstBlock.loopPlayer?.loopPlaying, false)
    XCTAssertEqual(secondBlock.isPlaying, true)
    XCTAssertEqual(secondBlock.loopPlayer?.loopPlaying, true)
  }

  func getTestBlock(id: Int, location: CGPoint) -> Block {
    return Block(
      id: id,
      location: CGPoint(x: 0, y: 0),
      color: .pink,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "TEST_FILE.wav", relativeTo: Bundle.main.bundleURL)
    )
  }
}
