//
//  CanvasModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI
import os

class CanvasModelData: Codable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasModelData.self)
  )

  var name: String
  var blocksGroups: [BlockGroup]
  var libraryData: LibraryData

  enum CodingKeys: String, CodingKey {
    case name
    case blocksGroups
    case library
  }

  init(name: String, blocksGroups: [BlockGroup], libraryData: LibraryData) {
    self.name = name
    self.blocksGroups = blocksGroups
    self.libraryData = libraryData
  }

  required init(from decoder: Decoder) throws {
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      name = try container.decode(String.self, forKey: .name)
      blocksGroups = try container.decode([BlockGroup].self, forKey: .blocksGroups)
      libraryData = try container.decode(LibraryData.self, forKey: .library)
    } catch {
      Self.logger.error("CanvasModelData decode error \(error)")
      throw error
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(blocksGroups, forKey: .blocksGroups)
    try container.encode(libraryData, forKey: .library)
  }
}

class CanvasModel: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasModel.self)
  )

  var musicEngine: MusicEngine?

  @Published var name: String = "MySong"
  @Published var thumnail: UIImage?

  @Published var blocksGroups: [BlockGroup] = []
  @Published var library: Library

  var data: CanvasModelData {
    return CanvasModelData(
      name: name,
      blocksGroups: blocksGroups,
      libraryData: library.data
    )
  }

  init(sampleSetStore: SampleSetStore?) {
    library = Library(sampleSetStore: sampleSetStore)
  }

  init(data: CanvasModelData, sampleSetStore: SampleSetStore?) {
    name = data.name
    blocksGroups = data.blocksGroups
    library = Library(libraryData: data.libraryData, sampleSetStore: sampleSetStore)
  }

  func cleanup() {
    for blockGroup in blocksGroups {
      blockGroup.cleanup()
    }
    musicEngine?.stop()
    musicEngine?.delegate = nil
    musicEngine = nil
  }

  func setMusicEngineAfterLoad(musicEngine: MusicEngine) {
    self.musicEngine = musicEngine
    musicEngine.delegate = self
    for blockGroup in blocksGroups {
      blockGroup.setMusicEngineAfterLoad(musicEngine: musicEngine)
    }
    musicEngine.tempo = library.tempo
  }

  func clear() {
    for blockGroup in blocksGroups {
      blockGroup.removeAllBlocks()
    }

    blocksGroups = []
  }

  func addBlockGroup(initialBlock: Block) {
    let newBlockGroup = BlockGroup(id: BlockGroup.getNextBlockGroupId(), block: initialBlock, musicEngine: musicEngine)
    blocksGroups.append(newBlockGroup)
  }

  func addBlockToExistingBlockGroup(blockGroup: BlockGroup, block: Block, slot: BlockGroupSlot) {
    block.location = slot.location
    blockGroup.addBlock(
      block: block,
      gridPosX: slot.gridPosX,
      gridPosY: slot.gridPosY)
  }

  func removeBlockGroup(blockGroup: BlockGroup) {
    blockGroup.musicEngine = nil
    blocksGroups.removeAll { $0.id == blockGroup.id }
  }

  func removeBlockFromBlockGroup(block: Block, blockGroup: BlockGroup) {
    // TODO - verify that block is actually in block group
    blockGroup.removeBlock(block: block)
    if blockGroup.allBlocks.isEmpty {
      removeBlockGroup(blockGroup: blockGroup)
    }
  }

  func findEligibleSlotForBlock(block: Block) -> (BlockGroup, BlockGroupSlot)? {
    let allCanvasBlocks = blocksGroups.flatMap { $0.allBlocks }
    for blockGroup in blocksGroups {
      for otherBlock in blockGroup.allBlocks where otherBlock.id != block.id {
        let neighborSlots = BlockGroupSlot.getNeighborSlots(for: otherBlock)
        var intersectingSlot: BlockGroupSlot?
        var minDist: CGFloat = 100000000.0
        for slot in neighborSlots {
          let diffX = block.location.x - slot.location.x
          let diffY = block.location.y - slot.location.y
          let dist = diffX * diffX + diffY * diffY
          if abs(diffX) < CanvasViewModel.blockSize && abs(diffY) < CanvasViewModel.blockSize && dist < minDist {
            intersectingSlot = slot
            minDist = dist
            break
          }
        }

        var availableSlot: BlockGroupSlot? = intersectingSlot
        for otherBlock in allCanvasBlocks where otherBlock.id != block.id {
          if otherBlock.location == availableSlot?.location {
            availableSlot = nil
            break
          }
        }

        // if slot is available, snap block there
        if let availableSlot = availableSlot {
          let otherBlockGridPosX = otherBlock.blockGroupGridPosX ?? 0
          let otherBlockGridPosY = otherBlock.blockGroupGridPosY ?? 0
          let newGridPosX = otherBlockGridPosX + availableSlot.gridPosX
          let newGridPosY = otherBlockGridPosY + availableSlot.gridPosY

          return (blockGroup, BlockGroupSlot(
            gridPosX: newGridPosX,
            gridPosY: newGridPosY,
            location: availableSlot.location))
        }
      }
    }
    return nil
  }

  func checkBlockPositionAndAddToAvailableGroup(block: Block) -> Bool {
    // Check all slots around all blocks to see if there is a connection
    if let (blockGroup, slot) = findEligibleSlotForBlock(block: block) {
      addBlockToExistingBlockGroup(blockGroup: blockGroup, block: block, slot: slot)
      return true
    }

    return false
  }
}

extension CanvasModel: MusicEngineDelegate {
  func tick(step16: Int) {
    for blocksGroup in blocksGroups {
      blocksGroup.tick(step16: step16)
    }
  }
}
