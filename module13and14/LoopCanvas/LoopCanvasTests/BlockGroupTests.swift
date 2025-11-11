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

  func testTickPlaysSingleBlockWithTwoBars() throws {
    let block = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    block.numBars = 2
    let blockGroup = BlockGroup(id: 0, block: block, musicEngine: musicEngine)

    XCTAssertEqual(blockGroup.currentPlayPosX, 1)
    XCTAssertEqual(block.isPlaying, false)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, false)

    let tick = musicEngine.nextBarLogicTick
    blockGroup.tick(step16: tick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(block.isPlaying, true)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, true)
    XCTAssertEqual(block.currentRelativeBar, 0)

    blockGroup.tick(step16: tick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 1)
    XCTAssertEqual(block.isPlaying, true)
    XCTAssertEqual(block.loopPlayer?.loopPlaying, true)
    XCTAssertEqual(block.currentRelativeBar, 1)
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

  func testTickAdvancesPlayToAdjacent2BarBlocks() throws {
    let firstBlock = getTestBlock(id: 0, location: CGPoint(x: 0, y: 0))
    firstBlock.numBars = 2
    let blockGroup = BlockGroup(id: 0, block: firstBlock, musicEngine: musicEngine)

    blockGroup.tick(step16: musicEngine.nextBarLogicTick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 0)
    XCTAssertEqual(firstBlock.isPlaying, true)
    XCTAssertEqual(firstBlock.loopPlayer?.loopPlaying, true)

    let rightSlot = SlotPostion.right.getSlot(relativeTo: firstBlock.location, xOffsetMultiple: 1)
    let secondBlock = getTestBlock(id: 1, location: rightSlot.location)
    secondBlock.numBars = 2
    blockGroup.addBlock(block: secondBlock, gridPosX: rightSlot.gridPosX, gridPosY: rightSlot.gridPosY)

    blockGroup.tick(step16: musicEngine.nextBarLogicTick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 1)
    XCTAssertEqual(firstBlock.isPlaying, true)
    XCTAssertEqual(firstBlock.loopPlayer?.loopPlaying, true)
    XCTAssertEqual(secondBlock.isPlaying, false)
    XCTAssertEqual(secondBlock.loopPlayer?.loopPlaying, false)

    blockGroup.tick(step16: musicEngine.nextBarLogicTick)

    XCTAssertEqual(blockGroup.currentPlayPosX, 2)
    XCTAssertEqual(firstBlock.isPlaying, false)
    XCTAssertEqual(firstBlock.loopPlayer?.loopPlaying, false)
    XCTAssertEqual(secondBlock.isPlaying, true)
    XCTAssertEqual(secondBlock.loopPlayer?.loopPlaying, true)
  }

  func testEncodeBlockToJSON() throws {
    let testBlock = getTestBlock(
      id: 0,
      location: CGPoint(x: 0, y: 0),
      blockGroupGridPosX: 0,
      blockGroupGridPosY: 0
    )

    let encoder = JSONEncoder()
    let blockJSONData = try encoder.encode(testBlock)

    let decoder = JSONDecoder()
    let decodedTestBlock = try decoder.decode(Block.self, from: blockJSONData)

    XCTAssertEqual(decodedTestBlock.id, testBlock.id)
    XCTAssertEqual(decodedTestBlock.location, testBlock.location)
    XCTAssertEqual(decodedTestBlock.color, testBlock.color)
    XCTAssertEqual(decodedTestBlock.icon, testBlock.icon)
    XCTAssertEqual(decodedTestBlock.relativePath, testBlock.relativePath)
    XCTAssertEqual(decodedTestBlock.loopURL, decodedTestBlock.loopURL)
    XCTAssertEqual(decodedTestBlock.blockGroupGridPosX, testBlock.blockGroupGridPosX)
    XCTAssertEqual(decodedTestBlock.blockGroupGridPosY, testBlock.blockGroupGridPosY)
    XCTAssertEqual(decodedTestBlock.normalColor, testBlock.normalColor)
    XCTAssertEqual(decodedTestBlock.visible, true)
    XCTAssertEqual(decodedTestBlock.isLibraryBlock, false)
  }

  func testEncodeBlockGroupToJSON() throws {
    let firstBlock = getTestBlock(
      id: 0,
      location: CGPoint(x: 0, y: 0),
      blockGroupGridPosX: 0,
      blockGroupGridPosY: 0
    )

    let blockGroup = BlockGroup(id: 0, block: firstBlock, musicEngine: musicEngine)

    let rightSlot = SlotPostion.right.getSlot(relativeTo: firstBlock)
    let secondBlock = getTestBlock(
      id: 1,
      location: rightSlot.location,
      blockGroupGridPosX: 0,
      blockGroupGridPosY: 0
    )

    blockGroup.addBlock(block: secondBlock, gridPosX: rightSlot.gridPosX, gridPosY: rightSlot.gridPosY)

    let encoder = JSONEncoder()
    let blockGroupJSONData = try encoder.encode(blockGroup)

    let decoder = JSONDecoder()
    let decodedBlockGroup = try decoder.decode(BlockGroup.self, from: blockGroupJSONData)

    XCTAssertEqual(decodedBlockGroup.id, blockGroup.id)
    XCTAssertEqual(decodedBlockGroup.allBlocks.count, blockGroup.allBlocks.count)

    for (ind, decodedBlock) in decodedBlockGroup.allBlocks.enumerated() {
      let origBlock = blockGroup.allBlocks[ind]
      XCTAssertEqual(decodedBlock.id, origBlock.id)
      XCTAssertEqual(decodedBlock.location, origBlock.location)
      XCTAssertEqual(decodedBlock.color, origBlock.color)
      XCTAssertEqual(decodedBlock.icon, origBlock.icon)
      XCTAssertEqual(decodedBlock.relativePath, origBlock.relativePath)
      XCTAssertEqual(decodedBlock.loopURL, origBlock.loopURL)
      XCTAssertEqual(decodedBlock.blockGroupGridPosX, origBlock.blockGroupGridPosX)
      XCTAssertEqual(decodedBlock.blockGroupGridPosY, origBlock.blockGroupGridPosY)
      XCTAssertEqual(decodedBlock.normalColor, origBlock.normalColor)
      XCTAssertEqual(decodedBlock.visible, true)
      XCTAssertEqual(decodedBlock.isLibraryBlock, false)
    }
  }

  func getTestBlock(id: Int, location: CGPoint, blockGroupGridPosX: Int? = nil, blockGroupGridPosY: Int? = nil) -> Block {
    let block = Block(
      id: id,
      location: location,
      color: .pink,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "Samples/Dub/Horns/horns-5.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "Samples/Dub/Horns/horns-5.wav"
    )
    block.blockGroupGridPosX = blockGroupGridPosX
    block.blockGroupGridPosY = blockGroupGridPosY
    return block
  }
}
