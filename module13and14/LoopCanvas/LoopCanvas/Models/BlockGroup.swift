//
//  BlockGroupModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation

struct BlockGroupSlot {
  let gridPosX: Int
  let gridPosY: Int
  let location: CGPoint
}

class BlockGroup: ObservableObject, Identifiable {
  var musicEngine: MusicEngine?

  let id: Int
  var allBlocks: [Block] = []
  var currentBlockGridXIndex = 0

  var currentPlayPosX = 0

  var isEmpty: Bool {
    allBlocks.isEmpty
  }

  static var blockGroupIdCounter: Int = 0
  static func getNextBlockGroupId() -> Int {
    let id = blockGroupIdCounter
    blockGroupIdCounter += 1
    return id
  }

  init() {
    id = 0
  }

  init(id: Int, block: Block, musicEngine: MusicEngine? = nil) {
    self.id = id
    self.musicEngine = musicEngine

    block.blockGroup = self
    block.blockGroupGridPosX = 0
    block.blockGroupGridPosY = 0
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL)
    block.isPlaying = true

    allBlocks.append(block)
  }

  func addBlock(block: Block, gridPosX: Int, gridPosY: Int) {
    block.blockGroupGridPosX = gridPosX
    block.blockGroupGridPosY = gridPosY
    block.blockGroup = self
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL)
    block.isPlaying = false
    allBlocks.append(block)
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
    block.blockGroupGridPosX = nil
    block.blockGroupGridPosY = nil
    block.blockGroup = nil
    if let loopPlayer = block.loopPlayer {
      musicEngine?.releaseLoopPlayer(player: loopPlayer)
    }
    block.loopPlayer = nil
    block.isPlaying = false
  }

  func getNextPlayPos() -> Int {
    if allBlocks.isEmpty {
      return 0
    }
    var maxPlayPosX = -10000
    var minPlayPosX = 10000
    for block in allBlocks {
      if let blockGroupGridPosX = block.blockGroupGridPosX {
        if blockGroupGridPosX > maxPlayPosX {
          maxPlayPosX = blockGroupGridPosX
        }
        if blockGroupGridPosX < minPlayPosX {
          minPlayPosX = blockGroupGridPosX
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
      let currentlyPlayingBlocks = allBlocks.filter { $0.blockGroupGridPosX == oldPlayPositionX }
      let currentlyPlayingBlockIds = currentlyPlayingBlocks.map { $0.id }
      let newPlayPositionX = getNextPlayPos()
      let newPlayingBlocks = allBlocks.filter { $0.blockGroupGridPosX == newPlayPositionX }
      let newPlayingBlockIds = newPlayingBlocks.map { $0.id }

      let blocksStarting = newPlayingBlocks.filter { !currentlyPlayingBlockIds.contains($0.id) }
      let blocksContinuing = newPlayingBlocks.filter { currentlyPlayingBlockIds.contains($0.id) }
      let blocksStopping = currentlyPlayingBlocks.filter { !newPlayingBlockIds.contains($0.id) }

      // print(" all blocks grid PosX = \(allBlocks.map { $0.blockGroupGridPosX })")
      // print("oldPlayPositionX \(oldPlayPositionX) newPlayPositionX \(newPlayPositionX)")
      // print("blocksStarting \(blocksStarting.map { $0.id })")
      // print("blocksContinuing \(blocksContinuing.map { $0.id })")
      // print("blocksStopping \(blocksStopping.map { $0.id })")

      for block in blocksStarting {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
      }
      for block in blocksContinuing {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
      }
      for block in blocksStopping {
        block.isPlaying = false
        block.loopPlayer?.loopPlaying = false
      }

      currentPlayPosX = newPlayPositionX
    }

    for block in allBlocks {
      block.tick(step16: step16)
    }
  }
}
