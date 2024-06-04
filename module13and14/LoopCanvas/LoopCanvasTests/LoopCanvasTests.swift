//
//  LoopCanvasTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 5/30/24.
//

import XCTest
@testable import LoopCanvas

final class LoopCanvasTests: XCTestCase {
  override func setUpWithError() throws {
  }

  func testDropFirstBlockOnCanvas() throws {
    let canvasViewModel = CanvasViewModel(canvasModel: CanvasModel())
    canvasViewModel.canvasModel.library.syncBlockLocationsWithSlots()

    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 0)
    XCTAssertEqual(canvasViewModel.canvasModel.library.blocks.count, 4)
    let blockToDrag = try XCTUnwrap(canvasViewModel.canvasModel.library.blocks.first)

    XCTAssertTrue(canvasViewModel.canvasModel.library.blocks.contains(blockToDrag))
    XCTAssertNil(blockToDrag.blockGroupGridPosX)
    XCTAssertNil(blockToDrag.blockGroupGridPosY)

    blockToDrag.location = CGPoint(x: 200, y: 400)

    canvasViewModel.dropBlockOnCanvas(block: blockToDrag)

    XCTAssertEqual(canvasViewModel.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)
    XCTAssertTrue(newBlockGroup.allBlocks.contains(blockToDrag))
    XCTAssertEqual(blockToDrag.blockGroupGridPosX, 0)
    XCTAssertEqual(blockToDrag.blockGroupGridPosY, 0)

    XCTAssertEqual(canvasViewModel.canvasModel.library.blocks.count, 4)
    XCTAssertFalse(canvasViewModel.canvasModel.library.blocks.contains(blockToDrag))
  }

  func testDropSecondBlockOnCanvasToConnect() throws {
  }

  func testDropSecondBlockOnCanvasToCreateNewGroup() throws {
  }
}
