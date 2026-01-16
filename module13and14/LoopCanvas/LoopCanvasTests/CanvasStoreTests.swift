//
//  CanvasStoreTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 8/15/24.
//

import XCTest
import os

final class CanvasStoreTests: XCTestCase {
  private static let logger = Logger(
    subsystem: "Tests",
    category: String(describing: CanvasStoreTests.self)
  )

  var canvasStore: CanvasStore!
  var sampleSetStore: SampleSetStore!

  override func setUpWithError() throws {
    sampleSetStore = SampleSetStore()
    canvasStore = CanvasStore(sampleSetStore: sampleSetStore)
  }

  func testSaveAndLoadSong() throws {
    let canvasModel = CanvasModel(sampleSetStore: sampleSetStore)
    canvasModel.setMusicEngineAfterLoad(musicEngine: MockMusicEngine())
    canvasModel.name = "CANVAS_STORE_TEST_CANVAS"
    canvasModel.thumnail = UIImage(systemName: "photo")

    let block = try getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: block)

    XCTAssertEqual(canvasModel.blocksGroups.count, 1)
    let origBlockGroup = try XCTUnwrap(canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup.allBlocks.count, 1)
    let origFirstBlock = try XCTUnwrap(origBlockGroup.allBlocks.first)
    XCTAssertEqual(origFirstBlock, block)

    canvasStore.saveCanvas(canvasModel: canvasModel)

    let newCanvasModel = canvasStore.loadCanvas(name: canvasModel.name)

    XCTAssertEqual(newCanvasModel?.name, "CANVAS_STORE_TEST_CANVAS")
    XCTAssertNotNil(newCanvasModel?.thumnail)
    XCTAssertEqual(newCanvasModel?.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(newCanvasModel?.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.id, origBlockGroup.id)
    XCTAssertEqual(newBlockGroup.allBlocks.count, origBlockGroup.allBlocks.count)
    let newFirstBlock = try XCTUnwrap(newBlockGroup.allBlocks.first { $0.id == origFirstBlock.id })
    XCTAssertEqual(newFirstBlock.color, origFirstBlock.color)
    XCTAssertEqual(newFirstBlock.relativePath, origFirstBlock.relativePath)
    XCTAssertEqual(newFirstBlock.blockGroupGridPosX, origFirstBlock.blockGroupGridPosX)
    XCTAssertEqual(newFirstBlock.blockGroupGridPosY, origFirstBlock.blockGroupGridPosY)
    XCTAssertEqual(newFirstBlock.location, origFirstBlock.location)
  }

  func testGetSavedCanvases() throws {
    let canvasModel = CanvasModel(sampleSetStore: sampleSetStore)
    canvasModel.setMusicEngineAfterLoad(musicEngine: MockMusicEngine())
    canvasModel.name = "CANVAS_STORE_TEST_CANVAS"
    canvasModel.thumnail = UIImage(systemName: "photo")

    let block = try getFirstTestBlock()
    canvasModel.addBlockGroup(initialBlock: block)

    canvasStore.saveCanvas(canvasModel: canvasModel)

    let savedCanvases = canvasStore.getSavedCanvases()

    XCTAssertTrue(savedCanvases.count >= 1)
    let firstSavedCanvas = try XCTUnwrap(savedCanvases.first { $0.name == "CANVAS_STORE_TEST_CANVAS" })
    XCTAssertNotNil(firstSavedCanvas)
    XCTAssertNotNil(firstSavedCanvas.thumnail)
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
}
