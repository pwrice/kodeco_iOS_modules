//
//  CanvasViewModel_MessageEvents.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/22/25.
//

import Foundation
import SwiftUI
import os

extension CanvasViewModel {
  func startSharing() {
    canvasMessageStore?.startSharing()
  }

  func processCanvasMessages(_ messages: [CanvasMessage]) {
    //    Self.logger.debug("Received canvas messages: \(messages.count)")

    for message in messages where message.viewModelId != self.id {
      // TODO - add some versioning logic to just process the last message
      if canvasVersion < message.canvasVersion {
        handle(message: message)
        canvasVersion = message.canvasVersion
      }
    }
  }

  func handleSharePlayUsersUpdated(_ sharePlayUsers: [SharePlayUser]) {
    self.sharePlayUsers = sharePlayUsers
    if let mySharePlayUser {
      if sharePlayHostUserId == nil, sharePlayUsers == [mySharePlayUser] {
        // if we are the first participant, set ourselves as the host
        self.sharePlayHostUserId = mySharePlayUser.id
      }

      if self.sharePlayHostUserId == mySharePlayUser.id {
        // when new users join, only the host sends the snapshot to them
        sendCanvasModelSnapshot()
      }
    }
  }

  func handleMySharePlayUsersUpdated(_ mySharePlayUser: SharePlayUser?) {
    if let mySharePlayUser {
      self.mySharePlayUser = mySharePlayUser
    }
  }


  private func handle(message: CanvasMessage) {
    Self.logger.debug("Received canvas message: \(message.canvasVersion) \(String(describing: message.self))")
    switch message {
    case let add as BlockAddedMessage:
      handleBlockAdded(add)
    case let move as BlockMovedMessage:
      handleBlockMoved(move)
    case let disconnect as BlockDisconnectedFromGroupMessage:
      handleBlockDisconnected(disconnect)
    case let deleted as BlockDeteledMessage:
      handleBlockDeleted(deleted)
    case let numBars as BlockNumBarsUpdatedMessage:
      handleNumBarsUpdated(numBars)
    case let startOffset as BlockStartOffsetUpdatedMessage:
      handleStartOffsetUpdated(startOffset)
    case let volume as BlockVolumeUpdatedMessage:
      handleVolumeUpdated(volume)
    case let mute as BlockIsMutedUpdatedMessage:
      handleIsMutedUpdated(mute)
    case let duplicate as BlockDuplicatedMessage:
      handleBlockDuplicated(duplicate)
    case let groupStart as BlockGroupStartedMoveMessage:
      handleBlockGroupStartedMove(groupStart)
    case let groupMoved as BlockGroupMovedMessage:
      handleBlockGroupMoved(groupMoved)
    case let canvasSnapshot as CanvasModelSnapshotMessage:
      handleCanvasSnapshot(canvasSnapshot)
    default:
      break
    }
  }

  private func handleBlockAdded(_ message: BlockAddedMessage) {
    if let newBlockGroupDTO = message.newBlockGroup {
      canvasModel.addBlockGroup(from: newBlockGroupDTO)
    } else {
      canvasModel.addBlockToExistingOrNewGroup(block: Block(dto: message.block))
    }
    updateAllBlocksList()
  }

  private func handleBlockMoved(_ message: BlockMovedMessage) {
    if let newBlockGroupDTO = message.newBlockGroup {
      canvasModel.addBlockGroup(from: newBlockGroupDTO)
      updateAllBlocksList()
    }
  }

  private func handleBlockDisconnected(_ message: BlockDisconnectedFromGroupMessage) {
    if let block = allBlocks.first(where: { $0.id == message.updatedBlock.id }),
       let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
      updateAllBlocksList()
    }
  }

  private func handleBlockDeleted(_ message: BlockDeteledMessage) {
    if let block = allBlocks.first(where: { $0.id == message.deletedBlock.id }),
       let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
      updateAllBlocksList()
    }
  }

  private func handleNumBarsUpdated(_ message: BlockNumBarsUpdatedMessage) {
    if let block = allBlocks.first(where: { $0.id == message.blockId }) {
      let newNumBars = message.numBars
      block.blockGroup?.updateBlockNumBars(block: block, newNumBars: newNumBars)
      updateAllBlocksList()
    }
  }

  private func handleStartOffsetUpdated(_ message: BlockStartOffsetUpdatedMessage) {
    if let block = allBlocks.first(where: { $0.id == message.blockId }) {
      let newStartOffset = message.startOffset
      block.blockGroup?.updateBlockStartOffset(block: block, newStartOffset: newStartOffset)
      updateAllBlocksList()
    }
  }

  private func handleVolumeUpdated(_ message: BlockVolumeUpdatedMessage) {
    if let block = allBlocks.first(where: { $0.id == message.blockId }) {
      let clamped = max(0.0, min(1.0, message.volume))
      block.volume = clamped
      updateAllBlocksList()
    }
  }

  private func handleIsMutedUpdated(_ message: BlockIsMutedUpdatedMessage) {
    if let block = allBlocks.first(where: { $0.id == message.blockId }) {
      block.isMuted = message.isMuted
      updateAllBlocksList()
    }
  }

  private func handleBlockDuplicated(_ message: BlockDuplicatedMessage) {
    let newBlock = Block(dto: message.block)
    canvasModel.addBlockToExistingOrNewGroup(block: newBlock)
    updateAllBlocksList()
  }

  private func handleBlockGroupStartedMove(_ message: BlockGroupStartedMoveMessage) {
    if let blockGroup = allBlockGroups.first(where: { $0.id == message.blockGroupId }) {
      blockGroup.isDragging = true
      updateAllBlocksList()
    }
  }

  private func handleBlockGroupMoved(_ message: BlockGroupMovedMessage) {
    if let blockGroup = allBlockGroups.first(where: { $0.id == message.blockGroupId }) {
      blockGroup.isDragging = false
      for block in blockGroup.allBlocks {
        block.location = message.updatedBlockLocations[block.id] ?? block.location
      }
      updateAllBlocksList()
    }
  }

  private func handleCanvasSnapshot(_ message: CanvasModelSnapshotMessage) {
    let newCanvasModel = CanvasModel(dto: message.canvasModel, sampleSetStore: sampleSetStore)
    // TODO - sync up the play position / bar to where the master is
    resetCanvasModel(newCanvasModel: newCanvasModel)
    sharePlayHostUserId = message.hostUserId
  }
}
