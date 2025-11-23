//
//  SharePlayTests.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/22/25.
//


import XCTest
import Combine

@testable import LoopCanvas

@MainActor
class SharePlayTestsBase: XCTestCase {
  var canvasModel1: CanvasModel!
  var canvasViewModel1: CanvasViewModel!
  var musicEngine1: MockMusicEngine!
  var canvasStore1: CanvasStore!
  var sampleSetStore1: SampleSetStore!
  var canvasMessageStore1: CanvasMessageStore!
  var mockGroupSessionWrapper1: MockGroupSessionWrapper!

  var canvasModel2: CanvasModel!
  var canvasViewModel2: CanvasViewModel!
  var musicEngine2: MockMusicEngine!
  var canvasStore2: CanvasStore!
  var sampleSetStore2: SampleSetStore!
  var canvasMessageStore2: CanvasMessageStore!
  var mockGroupSessionWrapper2: MockGroupSessionWrapper!


  var cancellables: Set<AnyCancellable> = []

  var testBlocks: [Block] = []

  override func setUpWithError() throws {
    testBlocks = [
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
    musicEngine1 = MockMusicEngine()
    sampleSetStore1 = SampleSetStore()
    canvasStore1 = CanvasStore(sampleSetStore: sampleSetStore1)
    canvasModel1 = CanvasModel(sampleSetStore: sampleSetStore1)
    mockGroupSessionWrapper1 = MockGroupSessionWrapper()
    canvasMessageStore1 = CanvasMessageStore(groupSessionWrapper: mockGroupSessionWrapper1)
    canvasViewModel1 = CanvasViewModel(
      canvasModel: canvasModel1,
      musicEngine: musicEngine1,
      canvasStore: canvasStore1,
      sampleSetStore: sampleSetStore1,
      canvasMessageStore: canvasMessageStore1,
      viewModelId: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000000")))
    canvasViewModel1.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    canvasViewModel1.updateAllBlocksList()

    musicEngine2 = MockMusicEngine()
    sampleSetStore2 = SampleSetStore()
    canvasStore2 = CanvasStore(sampleSetStore: sampleSetStore2)
    canvasModel2 = CanvasModel(sampleSetStore: sampleSetStore2)
    mockGroupSessionWrapper2 = MockGroupSessionWrapper()
    canvasMessageStore2 = CanvasMessageStore(groupSessionWrapper: mockGroupSessionWrapper2)
    canvasViewModel2 = CanvasViewModel(
      canvasModel: canvasModel2,
      musicEngine: musicEngine2,
      canvasStore: canvasStore2,
      sampleSetStore: sampleSetStore2,
      canvasMessageStore: canvasMessageStore2,
      viewModelId: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")))
    canvasViewModel2.canvasModel.library.loadLibraryFrom(libraryFolderName: "Dub")
    canvasViewModel2.updateAllBlocksList()


    // connect the two sessions together so that session wrapper 1
    // broadcasts to session wrapper 2
    mockGroupSessionWrapper1.linkedMockGroupSessionWrapper = mockGroupSessionWrapper2
  }
}

// Test Helpers

extension SharePlayTestsBase {
  func addBlockToCanvas(viewModel: CanvasViewModel, libraryBlockIndex: Int, location: CGPoint) throws -> Block {
    let blockToAdd = testBlocks[libraryBlockIndex]
    let newBlock = viewModel.addBlockToCanvasOnGrid(
      newBlock: blockToAdd.instantiateCopyWith(
        location: location, isLibraryBlock: false))
    return newBlock
  }

  func getCanvasVersionExpectations(viewModel: CanvasViewModel, expectedCanvasVersion: Int = 1) -> XCTestExpectation {
    cancellables.forEach { $0.cancel() }

    let versionExpectation = self.expectation(
      description: "Waiting canvasViewModel.canvasVersion to update"
    )

    viewModel.$canvasVersion
      .dropFirst()
      .sink { version in
        if version == expectedCanvasVersion {
          versionExpectation.fulfill()
        }
      }
      .store(in: &cancellables)

    return versionExpectation
  }

  func getSharePlayUserExpectations(viewModel: CanvasViewModel) -> (XCTestExpectation, XCTestExpectation) {
    cancellables.forEach { $0.cancel() }

    let expectation1 = self.expectation(description: "Waiting $sharePlayUsers to update")
    viewModel.$sharePlayUsers
      .dropFirst()
      .sink { _ in
        expectation1.fulfill()
      }
      .store(in: &cancellables)
    let expectation2 = self.expectation(description: "Waiting $mySharePlayUser to update")
    viewModel.$mySharePlayUser
      .dropFirst()
      .sink { _ in
        expectation2.fulfill()
      }
      .store(in: &cancellables)

    return (expectation1, expectation2)
  }

  func validateBlockPropertiesMatch(_ firstBlock: Block, _ blockToAdd: Block) {
    XCTAssertEqual(firstBlock.color, blockToAdd.color)
    XCTAssertEqual(firstBlock.relativePath, blockToAdd.relativePath)
    XCTAssertEqual(firstBlock.loopURL, blockToAdd.loopURL)
    XCTAssertFalse(firstBlock.isLibraryBlock)
    XCTAssertEqual(firstBlock.icon, blockToAdd.icon)
  }
}

final class SharePlayBlockMessageTests: SharePlayTestsBase {
  func testAddFirstBlockToCanvas() throws {
    // Initially neither viewmodel has any blockgroups
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 0)
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 0)

    let blockToAdd = Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 50, y: 150),
      color: .pink,
      icon: "circle",
      isLibraryBlock: false)

    let addBlockTapPosition = CGPoint(x: 200, y: 400)
    _ = canvasViewModel1.addBlockToCanvasOnGrid(
      newBlock: blockToAdd.instantiateCopyWith(
        location: addBlockTapPosition, isLibraryBlock: false))

    // A new block group is created on the local view model which contains a new block
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let newBlockGroup = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup.allBlocks.count, 1)

    // The new block is a clone of the dropped block
    let firstBlock = try XCTUnwrap(newBlockGroup.allBlocks.first)
    XCTAssertNotEqual(firstBlock.id, blockToAdd.id)
    validateBlockPropertiesMatch(firstBlock, blockToAdd)

    // The new block is setup properly
    XCTAssertEqual(firstBlock.blockGroupGridPosX, 0)
    XCTAssertEqual(firstBlock.blockGroupGridPosY, 0)

    let gridQuantizedLocation = CanvasViewModel.quantizedPoint(for: addBlockTapPosition)
    XCTAssertEqual(firstBlock.location.x, gridQuantizedLocation.x)
    XCTAssertEqual(firstBlock.location.y, gridQuantizedLocation.y)

    // The remote viewmodel still has no blockGroups
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 0)

    let allBlocksExpectation = getCanvasVersionExpectations(
      viewModel: canvasViewModel2)

    mockGroupSessionWrapper1.debugBroadCastMessages()

    wait(for: [allBlocksExpectation], timeout: 1.0)

    // Validate that the state of
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 1)
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let newBlockGroup2 = try XCTUnwrap(canvasViewModel2.canvasModel.blocksGroups.first)
    XCTAssertEqual(newBlockGroup2.allBlocks.count, 1)

    // The new block is a clone of the dropped block
    let firstBlock2 = try XCTUnwrap(newBlockGroup2.allBlocks.first)
    XCTAssertEqual(firstBlock2.id, firstBlock.id)
    validateBlockPropertiesMatch(firstBlock2, firstBlock)

    // The new block is setup properly
    XCTAssertEqual(firstBlock2.blockGroupGridPosX, 0)
    XCTAssertEqual(firstBlock2.blockGroupGridPosY, 0)
    XCTAssertEqual(firstBlock2.location.x, firstBlock.location.x)
    XCTAssertEqual(firstBlock2.location.y, firstBlock.location.y)
  }

  func testMoveExistingBlockToCreateNewGroup() throws {
    // Arrange: On device 1, add two connected blocks in one group
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let secondBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // Verify initial single group state on device 1
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let origBlockGroup1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertEqual(origBlockGroup1.allBlocks.count, 2)
    XCTAssertTrue(origBlockGroup1.allBlocks.contains(firstBlock))
    XCTAssertTrue(origBlockGroup1.allBlocks.contains(secondBlock))

    // Act: Drag second block away via CanvasViewModel API to create a new group
    canvasViewModel1.updateBlockDragLocation(
      block: secondBlock,
      location: CGPoint(
        x: secondBlock.location.x + CanvasViewModel.blockSize * 3,
        y: secondBlock.location.y))
    _ = canvasViewModel1.dropBlockOnCanvas(block: secondBlock)

    // Local assertions on device 1
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 2)
    XCTAssertEqual(origBlockGroup1.allBlocks.count, 1)
    XCTAssertTrue(origBlockGroup1.allBlocks.contains(firstBlock))
    XCTAssertFalse(origBlockGroup1.allBlocks.contains(secondBlock))
    let newGroup1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first { $0.id != origBlockGroup1.id })
    XCTAssertEqual(newGroup1.allBlocks.count, 1)
    XCTAssertTrue(newGroup1.allBlocks.contains(secondBlock))

    // Now verify device 2 receives the synchronized state via SharePlay
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2, expectedCanvasVersion: 4)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Assert: Both devices now have two groups with expected membership
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 2)

    // Device 2 checks mirror device 1
    let groups2 = canvasViewModel2.canvasModel.blocksGroups
    let maybeOrig2 = try XCTUnwrap(groups2.first { group in group.allBlocks.contains(where: { $0.id == firstBlock.id }) })
    let origBlockGroup2 = try XCTUnwrap(maybeOrig2)
    XCTAssertEqual(origBlockGroup2.allBlocks.count, 1)
    XCTAssertTrue(origBlockGroup2.allBlocks.contains(where: { $0.id == firstBlock.id }))
    XCTAssertFalse(origBlockGroup2.allBlocks.contains(where: { $0.id == secondBlock.id }))

    let newGroup2 = try XCTUnwrap(groups2.first { $0.id != origBlockGroup2.id })
    XCTAssertEqual(newGroup2.allBlocks.count, 1)
    XCTAssertTrue(newGroup2.allBlocks.contains(where: { $0.id == secondBlock.id }))
  }

  func testDeleteBlockFromExistingGroup() throws {
    // Arrange: add two connected blocks on device 1
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let secondBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 1,
      location: CGPoint(
        x: firstBlock.location.x + 20,
        y: firstBlock.location.y + CanvasViewModel.blockSize + 20))

    // Verify initial state on device 1
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let group1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertEqual(group1.allBlocks.count, 2)

    // Act: delete second block via CanvasViewModel on device 1
    canvasViewModel1.deleteBlockFromCanvas(block: secondBlock)

    // Assert local state on device 1
    XCTAssertTrue(group1.allBlocks.contains(firstBlock))
    XCTAssertFalse(group1.allBlocks.contains(secondBlock))
    XCTAssertFalse(canvasViewModel1.allBlocks.contains(secondBlock))

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Validate device 2 mirrors state
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 1)
    let group2 = try XCTUnwrap(canvasViewModel2.canvasModel.blocksGroups.first)
    XCTAssertTrue(group2.allBlocks.contains(where: { $0.id == firstBlock.id }))
    XCTAssertFalse(group2.allBlocks.contains(where: { $0.id == secondBlock.id }))
  }

  func testUpdateBlockNumBarsMessage() throws {
    // Arrange: add two connected blocks in one group on device 1
    let firstTestBlock = testBlocks[0]
    firstTestBlock.defaultMaxNumBars = 2
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    firstBlock.loopPlayer = nil
    let secondBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 1,
      location: CGPoint(x: firstBlock.location.x + CanvasViewModel.blockSize, y: firstBlock.location.y))

    // Capture original positions for assertions
    let originalSecondX = try XCTUnwrap(secondBlock.blockGroupGridPosX)
    let originalSecondLocationX = secondBlock.location.x

    // Act: grow first block to 2 bars via CanvasViewModel API
    canvasViewModel1.update(numBars: 2, for: firstBlock)

    // Local assertions on device 1
    XCTAssertEqual(firstBlock.numBars, 2)
    let expectedGridX = originalSecondX + 1
    XCTAssertEqual(secondBlock.blockGroupGridPosX, expectedGridX)
    let barPixelWidth = CanvasViewModel.blockSpacing + CanvasViewModel.blockSize
    XCTAssertEqual(secondBlock.location.x, originalSecondLocationX + barPixelWidth)

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2, expectedCanvasVersion: 3)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertions on device 2
    let groups2 = canvasViewModel2.canvasModel.blocksGroups
    XCTAssertEqual(groups2.count, 1)
    let group2 = try XCTUnwrap(groups2.first)
    let first2 = try XCTUnwrap(group2.allBlocks.first { $0.id == firstBlock.id })
    let second2 = try XCTUnwrap(group2.allBlocks.first { $0.id == secondBlock.id })
    XCTAssertEqual(first2.numBars, 2)
    XCTAssertEqual(second2.blockGroupGridPosX, expectedGridX)
    XCTAssertEqual(second2.location.x, originalSecondLocationX + barPixelWidth)
  }

  func testUpdateBlockStartOffsetMessage() throws {
    // Arrange: add one block on device 1
    let firstTestBlock = testBlocks[0]
    firstTestBlock.defaultMaxNumBars = 2
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    firstBlock.loopPlayer = nil
    XCTAssertEqual(firstBlock.startOffset, 0)

    // Act: update start offset via CanvasViewModel API
    let newStartOffset = 1
    canvasViewModel1.update(startOffset: newStartOffset, for: firstBlock)

    // Local assertion on device 1
    XCTAssertEqual(firstBlock.startOffset, newStartOffset)

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertion on device 2
    let groups2 = canvasViewModel2.canvasModel.blocksGroups
    let group2 = try XCTUnwrap(groups2.first)
    let first2 = try XCTUnwrap(group2.allBlocks.first { $0.id == firstBlock.id })
    XCTAssertEqual(first2.startOffset, newStartOffset)
  }

  func testUpdateBlockVolumeMessage() throws {
    // Arrange: add a single block on device 1
    let block = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let originalVolume = block.volume

    // Act: update volume via CanvasViewModel API
    let newVolume = 0.25
    canvasViewModel1.update(volume: newVolume, for: block)

    // Local assertion on device 1
    XCTAssertNotEqual(block.volume, originalVolume)
    XCTAssertEqual(block.volume, newVolume, accuracy: 0.0001)

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertion on device 2
    let groups2 = canvasViewModel2.canvasModel.blocksGroups
    let group2 = try XCTUnwrap(groups2.first)
    let block2 = try XCTUnwrap(group2.allBlocks.first { $0.id == block.id })
    XCTAssertEqual(block2.volume, newVolume)
  }

  func testUpdateBlockIsMutedMessage() throws {
    // Arrange: add a single block on device 1
    let block = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let originalMuted = block.isMuted

    // Act: toggle mute via CanvasViewModel API
    let newMuted = !originalMuted
    canvasViewModel1.toggleMute(block: block)

    // Local assertion on device 1
    XCTAssertEqual(block.isMuted, newMuted)

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertion on device 2
    let groups2 = canvasViewModel2.canvasModel.blocksGroups
    let group2 = try XCTUnwrap(groups2.first)
    let block2 = try XCTUnwrap(group2.allBlocks.first { $0.id == block.id })
    XCTAssertEqual(block2.isMuted, newMuted)
  }

  func testDuplicateBlockMessage() throws {
    // Arrange: add a single block to create an initial group on device 1
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let group1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertEqual(group1.allBlocks.count, 1)

    // Act: duplicate the block via CanvasViewModel API
    canvasViewModel1.duplicate(block: firstBlock)

    // Local assertions on device 1
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    XCTAssertEqual(group1.allBlocks.count, 2)

    // Identify the duplicate (different id, same icon/color) and expected position
    let duplicate1 = try XCTUnwrap(group1.allBlocks.first { $0.id != firstBlock.id })
    let expectedX = firstBlock.location.x + CanvasViewModel.gridSpacing()
    XCTAssertEqual(duplicate1.location.y, firstBlock.location.y)
    XCTAssertEqual(duplicate1.location.x, expectedX)

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2, expectedCanvasVersion: 2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertions on device 2
    let group2 = try XCTUnwrap(canvasViewModel2.canvasModel.blocksGroups.first)
    XCTAssertEqual(group2.allBlocks.count, 2)
    let duplicate2 = try XCTUnwrap(group2.allBlocks.first { $0.id != firstBlock.id })
    XCTAssertEqual(duplicate2.location.y, firstBlock.location.y)
    XCTAssertEqual(duplicate2.location.x, expectedX)
  }
}

final class SharePlayBlockGroupMessageTests: SharePlayTestsBase {
  func testMoveBlockGroupViaMessages() throws {
    // Arrange: add a single block to create a group on device 1
    let firstBlock = try addBlockToCanvas(
      viewModel: canvasViewModel1, libraryBlockIndex: 0, location: CGPoint(x: 200, y: 400))
    let group1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertFalse(group1.isDragging)

    // Keep a map of original locations by block id for later verification
    var originalLocations: [UUID: CGPoint] = [:]
    for block in group1.allBlocks {
      originalLocations[block.id] = block.location
    }

    // Act 1: start moving the group via CanvasViewModel API
    canvasViewModel1.startBlockGroupDrag(blockGroup: group1)

    // Local assertion
    XCTAssertTrue(group1.isDragging)

    // Act 2: move the group by delta via CanvasViewModel API
    let deltaX: CGFloat = 30
    let deltaY: CGFloat = -20
    let dropPosition = CGPoint(x: firstBlock.location.x + deltaX, y: firstBlock.location.y + deltaY)
    canvasViewModel1.updateBlockGroupDragLocation(
      blockGroup: group1,
      location: dropPosition)

    canvasViewModel1.dropBlockGroupOnCanvas(blockGroup: group1)

    // Local assertions: dragging ended and block locations updated
    XCTAssertFalse(group1.isDragging)
    for block in group1.allBlocks {
      let orig = try XCTUnwrap(originalLocations[block.id])
      let movedTo = CGPoint(x: orig.x + deltaX, y: orig.y + deltaY)
      let quantized = CanvasViewModel.quantizedPoint(for: movedTo)
      XCTAssertEqual(block.location.x, quantized.x)
      XCTAssertEqual(block.location.y, quantized.y)
    }

    // Broadcast and wait for device 2 to update
    let allBlocksExpectation2 = getCanvasVersionExpectations(viewModel: canvasViewModel2)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [allBlocksExpectation2], timeout: 1.0)

    // Mirror assertions on device 2
    let group2 = try XCTUnwrap(canvasViewModel2.canvasModel.blocksGroups.first)
    for block in group2.allBlocks {
      let orig = try XCTUnwrap(originalLocations[block.id])
      let movedTo = CGPoint(x: orig.x + deltaX, y: orig.y + deltaY)
      let quantized = CanvasViewModel.quantizedPoint(for: movedTo)
      XCTAssertEqual(block.location.x, quantized.x)
      XCTAssertEqual(block.location.y, quantized.y)
    }
  }
}


final class SharePlayLifeCycleTests: SharePlayTestsBase {
  func testCanvasSnapshotMessageSetsUpRemoteState() throws {
    let localUser = SharePlayUser(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000011")))
    canvasViewModel1.sharePlayHostUserId = localUser.id

    // Arrange: add three connected blocks on device 1 making an L-shape
    let first = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 0,
      location: CGPoint(x: 200, y: 400)
    )

    let rightOfFirst = CGPoint(
      x: first.location.x + CanvasViewModel.gridSpacing(),
      y: first.location.y
    )
    let second = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 1,
      location: rightOfFirst
    )

    let belowFirst = CGPoint(
      x: first.location.x,
      y: first.location.y + CanvasViewModel.gridSpacing()
    )
    let third = try addBlockToCanvas(
      viewModel: canvasViewModel1,
      libraryBlockIndex: 2,
      location: belowFirst
    )

    // Tweak some properties to ensure snapshot carries configuration
    first.numBars = 2
    second.startOffset = 1
    canvasViewModel1.toggleMute(block: third)

    // Local assertions on device 1
    XCTAssertEqual(canvasViewModel1.canvasModel.blocksGroups.count, 1)
    let group1 = try XCTUnwrap(canvasViewModel1.canvasModel.blocksGroups.first)
    XCTAssertEqual(group1.allBlocks.count, 3)

    // Clear any queued messages before sending the snapshot
    mockGroupSessionWrapper1.debugClearMessageQueue()

    // Act: send snapshot so only CanvasSnapshotMessage is broadcast
    canvasViewModel1.sendCanvasModelSnapshot()

    // Expect canvasVersion to update on device 2 to match device 1
    let expectedVersion = canvasViewModel1.canvasVersion
    let versionExpectation = getCanvasVersionExpectations(
      viewModel: canvasViewModel2,
      expectedCanvasVersion: expectedVersion
    )

    // Broadcast queued messages (only the snapshot)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [versionExpectation], timeout: 1.0)

    // Mirror assertions on device 2
    XCTAssertEqual(canvasViewModel2.canvasModel.blocksGroups.count, 1)
    let group2 = try XCTUnwrap(canvasViewModel2.canvasModel.blocksGroups.first)
    XCTAssertEqual(group2.allBlocks.count, 3)

    // Match blocks by id
    let first2 = try XCTUnwrap(group2.allBlocks.first { $0.id == first.id })
    let second2 = try XCTUnwrap(group2.allBlocks.first { $0.id == second.id })
    let third2 = try XCTUnwrap(group2.allBlocks.first { $0.id == third.id })

    // Validate properties replicated
    XCTAssertEqual(first2.numBars, 2)
    XCTAssertEqual(second2.startOffset, 1)
    XCTAssertEqual(third2.isMuted, true)

    // Validate common block properties via helper
    validateBlockPropertiesMatch(first2, first)
    validateBlockPropertiesMatch(second2, second)
    validateBlockPropertiesMatch(third2, third)

    // Validate locations quantized to grid positions we expect
    XCTAssertEqual(first2.location.x, first.location.x)
    XCTAssertEqual(first2.location.y, first.location.y)
    XCTAssertEqual(second2.location.x, second.location.x)
    XCTAssertEqual(second2.location.y, second.location.y)
    XCTAssertEqual(third2.location.x, third.location.x)
    XCTAssertEqual(third2.location.y, third.location.y)
  }

  func testSharePlaySetupAndParticipantJoin() throws {
    // By defualt, not eligible to share by default
    XCTAssertFalse(canvasViewModel1.canvasMessageStore?.eligibleToStartSharing ?? false)

    // No SharePlayUser stuff setup
    XCTAssertNil(canvasViewModel1.mySharePlayUser)
    XCTAssertNil(canvasViewModel1.sharePlayUsers)
    XCTAssertNil(canvasViewModel1.sharePlayHostUserId)

    // Simulate connecting over facetime
    canvasViewModel1.canvasMessageStore?.setEligableToStartSharing(true)

    // Now we can show the share button
    XCTAssertTrue(canvasViewModel1.canvasMessageStore?.eligibleToStartSharing ?? false)

    let (expectation1, expectation2) = getSharePlayUserExpectations(viewModel: canvasViewModel1)

    // User taps the share button
    canvasViewModel1.startSharing()

    // These would be called by the SharePlay infra setting up the session
    canvasViewModel1.canvasMessageStore?.setEligableToStartSharing(true)
    let localUser = SharePlayUser(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000011")))
    canvasViewModel1.canvasMessageStore?.setLocalSharePlayUser(user: localUser)
    canvasViewModel1.canvasMessageStore?.activeParticipantsChanged(sharePlayUsers: [localUser])

    // Wait for the state to propagte
    wait(for: [expectation1, expectation2], timeout: 1.0)

    // Once we start sharing, the share button goes away again b/c we have an active session
    XCTAssertFalse(canvasViewModel1.canvasMessageStore?.eligibleToStartSharing ?? false)

    // Validate that we have 1 SharePlayUser, that it is us, and that it is the host
    XCTAssertEqual(canvasViewModel1.sharePlayUsers?.count, 1)
    let firstUser = try XCTUnwrap(canvasViewModel1.sharePlayUsers?.first)
    XCTAssertEqual(canvasViewModel1.mySharePlayUser, firstUser)
    XCTAssertEqual(canvasViewModel1.sharePlayHostUserId, firstUser.id)

    // Now simulate someone else joining

    // By defualt, not eligible to share by default
    XCTAssertFalse(canvasViewModel2.canvasMessageStore?.eligibleToStartSharing ?? false)

    // No SharePlayUser stuff setup
    XCTAssertNil(canvasViewModel2.mySharePlayUser)
    XCTAssertNil(canvasViewModel2.sharePlayUsers)
    XCTAssertNil(canvasViewModel2.sharePlayHostUserId)

    // Simulate connecting over facetime
    canvasViewModel2.canvasMessageStore?.setEligableToStartSharing(true)

    // Now we can show the share button
    XCTAssertTrue(canvasViewModel2.canvasMessageStore?.eligibleToStartSharing ?? false)

    let (expectation3, expectation4) = getSharePlayUserExpectations(viewModel: canvasViewModel2)

    // User taps the join button
    canvasViewModel2.startSharing()

    // These would be called by the SharePlay infra setting up the session
    canvasViewModel2.canvasMessageStore?.setEligableToStartSharing(true)
    let localUser2 = SharePlayUser(id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000022")))
    canvasViewModel2.canvasMessageStore?.setLocalSharePlayUser(user: localUser2)

    // Now there are 2 active particpants
    canvasViewModel2.canvasMessageStore?.activeParticipantsChanged(sharePlayUsers: [localUser, localUser2])

    // Wait for the state to propagte
    wait(for: [expectation3, expectation4], timeout: 1.0)

    // Once we start sharing, the join button goes away again b/c we have an active session
    XCTAssertFalse(canvasViewModel2.canvasMessageStore?.eligibleToStartSharing ?? false)

    // Validate that we now have 2 SharePlayUsers, that it is us, and that it is the host
    XCTAssertEqual(canvasViewModel2.sharePlayUsers?.count, 2)
    let newUser = try XCTUnwrap(canvasViewModel2.sharePlayUsers?.first { $0.id == localUser2.id })
    XCTAssertEqual(canvasViewModel2.mySharePlayUser, newUser)

    // The host user id has not been set yet
    XCTAssertNil(canvasViewModel2.sharePlayHostUserId)

    let expectedVersion = canvasViewModel1.canvasVersion
    let versionExpectation = getCanvasVersionExpectations(
      viewModel: canvasViewModel2,
      expectedCanvasVersion: expectedVersion
    )

    // User 1 will be notified of new participants as well
    canvasViewModel1.canvasMessageStore?.activeParticipantsChanged(sharePlayUsers: [localUser, localUser2])
    // Which will trigger it to send a canvasModelSnapShot which will include the sharePlayHostUserId

    // Broadcast queued messages (only the snapshot)
    mockGroupSessionWrapper1.debugBroadCastMessages()
    wait(for: [versionExpectation], timeout: 1.0)

    // The host user id is now the same
    XCTAssertEqual(canvasViewModel2.sharePlayHostUserId, canvasViewModel1.sharePlayHostUserId)
  }
}
