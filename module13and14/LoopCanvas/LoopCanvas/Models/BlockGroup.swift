//
//  BlockGroupModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation
import os

struct BlockGroupDTO: Codable {
  let id: UUID
  let allBlocks: [BlockDTO]
}

enum SlotPostion {
  case top
  case right
  case bottom
  case left

  func getSlot(relativeTo block: Block) -> BlockGroupSlot {
    return getSlot(relativeTo: block.location)
  }

  func getSlot(relativeTo location: CGPoint, xOffsetMultiple: Int = 0) -> BlockGroupSlot {
    switch self {
    case .top:
      return BlockGroupSlot(
        gridPosX: xOffsetMultiple,
        gridPosY: -1,
        location: CGPoint(
          x: location.x +
            (CGFloat(xOffsetMultiple) * (CanvasViewModel.blockSpacing + CanvasViewModel.blockSize)),
          y: location.y - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize))
    case .right:
      return BlockGroupSlot(
        gridPosX: 1 + xOffsetMultiple,
        gridPosY: 0,
        location: CGPoint(
          x: location.x +
            CanvasViewModel.blockSpacing + CanvasViewModel.blockSize +
            (CGFloat(xOffsetMultiple) * (CanvasViewModel.blockSpacing + CanvasViewModel.blockSize)),
          y: location.y))
    case .bottom:
      return BlockGroupSlot(
        gridPosX: xOffsetMultiple,
        gridPosY: 1,
        location: CGPoint(
          x: location.x +
            (CGFloat(xOffsetMultiple) * (CanvasViewModel.blockSpacing + CanvasViewModel.blockSize)),
          y: location.y + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize))
    case .left:
      return BlockGroupSlot(
        gridPosX: -1,
        gridPosY: 0,
        location: CGPoint(
          x: location.x - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize,
          y: location.y))
    }
  }
}

struct BlockGroupSlot {
  let gridPosX: Int
  let gridPosY: Int
  let location: CGPoint

  static func getNeighborSlots(for block: Block) -> [BlockGroupSlot] {
    var neighborSlots: [BlockGroupSlot] = [
      SlotPostion.left.getSlot(relativeTo: block.location)
    ]
    for i in 0..<block.numBars {
      neighborSlots.append(SlotPostion.top.getSlot(relativeTo: block.location, xOffsetMultiple: i))
      neighborSlots.append(SlotPostion.bottom.getSlot(relativeTo: block.location, xOffsetMultiple: i))
      if i == block.numBars - 1 {
        neighborSlots.append(SlotPostion.right.getSlot(relativeTo: block.location, xOffsetMultiple: i))
      }
    }

    return neighborSlots
  }
}

class BlockGroup: ObservableObject, Identifiable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: BlockGroup.self)
  )

  var musicEngine: MusicEngine?

  let id: UUID
  var allBlocks: [Block] = []

  var currentPlayPosX = 0

  var isSelected = false
  var volume = 0.75

  var isEmpty: Bool {
    allBlocks.isEmpty
  }

  init() {
    id = UUID()
  }

  convenience init(dto: BlockGroupDTO, musicEngine: MusicEngine? = nil) {
    let blocks = dto.allBlocks.map { Block(dto: $0) }
    self.init(id: dto.id, blocks: blocks, musicEngine: musicEngine)
  }

  // Add a designated initializer to allow setting `id` directly for DTO construction
  init(id: UUID, blocks: [Block] = [], musicEngine: MusicEngine? = nil) {
    self.id = id
    self.musicEngine = musicEngine
    self.allBlocks = []
    self.currentPlayPosX = 0
    // Attach blocks
    for block in blocks {
      addBlock(block: block, gridPosX: block.blockGroupGridPosX ?? 0, gridPosY: block.blockGroupGridPosY ?? 0)
    }
  }

  init(id: UUID, block: Block, musicEngine: MusicEngine? = nil) {
    self.id = id
    self.musicEngine = musicEngine

    block.blockGroup = self
    block.blockGroupGridPosX = 0
    block.blockGroupGridPosY = 0
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL, numBars: block.numBars)
    block.isPlaying = false
    block.triggerBlockLoadingAnimation = true

    allBlocks.append(block)
    // when creating a new group, initialize at the end so the next bar starts at 0
    currentPlayPosX = block.numBars - 1
    block.currentRelativeBar = block.numBars - 1
  }

  func cleanup() {
    for block in allBlocks {
      if let loopPlayer = block.loopPlayer {
        musicEngine?.releaseLoopPlayer(player: loopPlayer)
      }
    }
    musicEngine = nil
  }

  func setMusicEngineAfterLoad(musicEngine: MusicEngine) {
    self.musicEngine = musicEngine
    for block in allBlocks where block.loopPlayer == nil {
      block.loopPlayer = musicEngine.getAvailableLoopPlayer(loopURL: block.loopURL, numBars: block.numBars)
    }
  }

  func addBlock(block: Block, gridPosX: Int, gridPosY: Int) {
    block.blockGroupGridPosX = gridPosX
    block.blockGroupGridPosY = gridPosY
    block.blockGroup = self
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL, numBars: block.numBars)
    block.isPlaying = false
    block.triggerBlockLoadingAnimation = true
    if allBlocks.isEmpty {
      // when creating a new group, initialize at the end so the next bar starts at 0
      currentPlayPosX = block.numBars - 1
      block.currentRelativeBar = block.numBars - 1
    }
    allBlocks.append(block)
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
    cleanUpBlock(block: block)
  }

  func cleanUpBlock(block: Block) {
    block.blockGroupGridPosX = nil
    block.blockGroupGridPosY = nil
    block.blockGroup = nil
    if let loopPlayer = block.loopPlayer {
      musicEngine?.releaseLoopPlayer(player: loopPlayer)
      block.loopPlayer = nil
    }
    block.loopPlayer = nil
    block.isPlaying = false
  }

  func removeAllBlocks() {
    for block in allBlocks {
      cleanUpBlock(block: block)
    }
    allBlocks = []
  }

  func getNextPlayPos() -> Int {
    if allBlocks.isEmpty {
      return 0
    }
    var maxPlayPosX = -10000
    var minPlayPosX = 10000
    for block in allBlocks {
      if let minBlockGroupGridPosX = block.startBlockGroupGridPosX,
        let maxBlockGroupGridPosX = block.endBlockGroupGridPosX {
        if maxBlockGroupGridPosX > maxPlayPosX {
          maxPlayPosX = maxBlockGroupGridPosX
        }
        if minBlockGroupGridPosX < minPlayPosX {
          minPlayPosX = minBlockGroupGridPosX
        }
      }
    }

    var newPlayPosX = currentPlayPosX + 1
    if newPlayPosX > maxPlayPosX {
      newPlayPosX = minPlayPosX
    }
    return newPlayPosX
  }

  func tick(step16: Int) {
    if step16 == musicEngine?.nextBarLogicTick {
      let oldPlayPositionX = currentPlayPosX
      let currentlyPlayingBlocks = allBlocks.filter {
        $0.blockGroupXSpanContains(posX: oldPlayPositionX)
      }
      let currentlyPlayingBlockIds = currentlyPlayingBlocks.map { $0.id }
      let newPlayPositionX = getNextPlayPos()
      let newPlayingBlocks = allBlocks.filter {
        $0.blockGroupXSpanContains(posX: newPlayPositionX)
      }
      let newPlayingBlockIds = newPlayingBlocks.map { $0.id }

      let blocksStarting = newPlayingBlocks.filter { !currentlyPlayingBlockIds.contains($0.id) }
      let blocksContinuing = newPlayingBlocks.filter { currentlyPlayingBlockIds.contains($0.id) }
      let blocksStopping = currentlyPlayingBlocks.filter { !newPlayingBlockIds.contains($0.id) }

      for block in blocksStarting {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
        block.currentRelativeBar = 0
      }
      for block in blocksContinuing {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
        block.currentRelativeBar = newPlayPositionX - (block.startBlockGroupGridPosX ?? 0)
      }
      for block in blocksStopping {
        block.isPlaying = false
        block.loopPlayer?.loopPlaying = false
        block.currentRelativeBar = 0
      }

      currentPlayPosX = newPlayPositionX
    }

    for block in allBlocks {
      block.tick(step16: step16)
    }
  }

  func updateBlockStartOffset(block: Block, newStartOffset: Int) {
    let clampedNew = max(0, min(block.maxNumBars - 1, newStartOffset))
    block.startOffset = clampedNew
    block.loopPlayer?.updateStartOffset(clampedNew)
  }

  /// Updates the given block's number of bars and shifts neighbor blocks in the group accordingly.
  /// - Parameters:
  ///   - block: The block whose length is changing.
  ///   - newNumBars: The new number of bars for the block.
  ///
  /// This function adjusts all blocks that start to the right of the changed block by the delta in bars.
  /// If the block grows, neighbors shift right; if it shrinks, neighbors shift left. It updates both the
  /// grid positions and physical locations to remain consistent with CanvasViewModel spacing and size.
  func updateBlockNumBars(block: Block, newNumBars: Int) {
    // Guard against no-op or invalid values
    let clampedNew = max(1, min(block.maxNumBars, newNumBars))
    let oldNumBars = block.numBars
    let delta = clampedNew - oldNumBars
    guard delta != 0 else { return }

    // Establish the anchor X (start) for the changed block
    guard let startX = block.startBlockGroupGridPosX else { return }

    // Capture the changed block's old end X before modification
    let oldEndX = startX + (oldNumBars - 1)

    // Compute the pixel delta for x location shift based on bars
    let barPixelWidth = CanvasViewModel.blockSpacing + CanvasViewModel.blockSize
    let pixelDelta = CGFloat(delta) * barPixelWidth

    // Identify blocks that should shift: those whose start is strictly to the right of the changed block's old end
    let shouldShift: (Block) -> Bool = { other in
      guard other.id != block.id, let otherStart = other.startBlockGroupGridPosX else { return false }
      return otherStart > oldEndX
    }

    // Shift all affected blocks by delta in grid space and pixel space
    for other in allBlocks where shouldShift(other) {
      // Shift writable grid position (only X is affected for linear sequence)
      if let x = other.blockGroupGridPosX {
        other.blockGroupGridPosX = x + delta
      }
      // Do not write to get-only span properties; their getters should reflect derived values

      // Shift the visual location horizontally
      other.location = CGPoint(x: other.location.x + pixelDelta, y: other.location.y)
    }

    // Adjust the group's currentPlayPosX if it is to the right of the changed block's old end
    if currentPlayPosX > oldEndX {
      currentPlayPosX += delta
    }

    // Update the block's own numBars
    block.numBars = clampedNew
    block.loopPlayer?.updateNumBars(clampedNew)
  }

  var leftMostBlock: Block? {
    return allBlocks.min(by: { lhs, rhs in lhs.location.x < rhs.location.x })
  }

  // Codable implementation

  enum CodingKeys: String, CodingKey {
    case id,
      allBlocks
  }

  func toDTO() -> BlockGroupDTO {
    let blockDTOs = allBlocks.map { $0.toDTO() }
    return BlockGroupDTO(id: id, allBlocks: blockDTOs)
  }
}
