//
//  CanvasModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI
import os

struct CanvasModelDTO: Codable {
  let name: String
  let blocksGroups: [BlockGroupDTO]
  let library: LibraryDTO
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

  func toDTO() -> CanvasModelDTO {
    let groupDTOs = blocksGroups.map { $0.toDTO() }
    return CanvasModelDTO(name: name, blocksGroups: groupDTOs, library: library.data)
  }

  init(sampleSetStore: SampleSetStore?) {
    library = Library(sampleSetStore: sampleSetStore)
  }

  convenience init(dto: CanvasModelDTO, sampleSetStore: SampleSetStore?) {
    self.init(sampleSetStore: sampleSetStore)
    self.name = dto.name
    // Build Library from LibraryData
    self.library = Library(libraryData: dto.library, sampleSetStore: sampleSetStore)
    // Build BlockGroups from DTOs; musicEngine will be attached later via setMusicEngineAfterLoad
    self.blocksGroups = dto.blocksGroups.map { BlockGroup(dto: $0) }
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

  @discardableResult
  func addBlockGroup(initialBlock: Block, mutateModel: Bool = true) -> BlockGroup {
    let newBlockGroup = BlockGroup(id: UUID(), block: initialBlock, musicEngine: musicEngine)
    if mutateModel {
      blocksGroups.append(newBlockGroup)
    }
    return newBlockGroup
  }

  func addBlockGroup(from blockGroupDTO: BlockGroupDTO) {
    let newBlockGroup = BlockGroup(dto: blockGroupDTO, musicEngine: musicEngine)
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

  @discardableResult
  func removeBlockFromBlockGroup(block: Block, blockGroup: BlockGroup) -> BlockGroup {
    // TODO - verify that block is actually in block group
    blockGroup.removeBlock(block: block)
    if blockGroup.allBlocks.isEmpty {
      removeBlockGroup(blockGroup: blockGroup)
    }
    return blockGroup
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

  func addBlockToExistingOrNewGroup(block: Block, mutateModel: Bool = true) -> (Block, BlockGroup?) {
    var newBlockGroup: BlockGroup?
    var existingBlockGroup: BlockGroup?

    // Check all slots around all blocks to see if there is a connection
    if let (blockGroup, slot) = findEligibleSlotForBlock(block: block) {
      existingBlockGroup = mutateModel ? blockGroup : BlockGroup(dto: blockGroup.toDTO())
      addBlockToExistingBlockGroup(blockGroup: blockGroup, block: block, slot: slot)
    }

    if existingBlockGroup == nil {
      newBlockGroup = addBlockGroup(initialBlock: block, mutateModel: mutateModel)
    }

    return (block, newBlockGroup)
  }
}

extension CanvasModel: MusicEngineDelegate {
  func tick(step16: Int) {
    for blocksGroup in blocksGroups {
      blocksGroup.tick(step16: step16)
    }
  }
}
