//
//  CanvasMessageStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/16/25.
//

import Foundation
import os

protocol CanvasMessage: Codable {
  var canvasVersion: Int { get }
  var viewModelId: UUID { get }
}

struct BlockAddedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let block: BlockDTO
  let newBlockGroup: BlockGroupDTO?
}

struct BlockDisconnectedFromGroupMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let updatedBlock: BlockDTO
}

struct BlockMovedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let updatedBlock: BlockDTO
  let newBlockGroup: BlockGroupDTO?
}

struct BlockDeteledMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let deletedBlock: BlockDTO
}

struct BlockNumBarsUpdatedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockId: UUID
  let numBars: Int
}

struct BlockStartOffsetUpdatedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockId: UUID
  let startOffset: Int
}

struct BlockVolumeUpdatedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockId: UUID
  let volume: Double
}

struct BlockIsMutedUpdatedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockId: UUID
  let isMuted: Bool
}

struct BlockDuplicatedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let block: BlockDTO
}


// Manages browsing, loading, saving of canvas
class CanvasMessageStore: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasMessageStore.self)
  )

  // Message State
  var canvasVersion = 0
  @Published var messages: [CanvasMessage]

  init() {
    self.messages = []
  }

  func addBlockToCanvasOnGrid(viewModelId: UUID, newBlock: Block, newGroup: BlockGroup?) {
    canvasVersion += 1
    let message = BlockAddedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      block: newBlock.toDTO(),
      newBlockGroup: newGroup?.toDTO())
    messages.append(message)
  }

  func disconnectBlockFromGroupMessage(viewModelId: UUID, updatedBlock: Block) {
    canvasVersion += 1
    let message = BlockDisconnectedFromGroupMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      updatedBlock: updatedBlock.toDTO())
    messages.append(message)
  }

  func moveBlock(viewModelId: UUID, updatedBlock: Block, newGroup: BlockGroup?) {
    canvasVersion += 1
    let message = BlockMovedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      updatedBlock: updatedBlock.toDTO(),
      newBlockGroup: newGroup?.toDTO())
    messages.append(message)
  }

  func deleteBlock(viewModelId: UUID, deletedBlock: Block) {
    canvasVersion += 1
    let message = BlockDeteledMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      deletedBlock: deletedBlock.toDTO())
    messages.append(message)
  }

  func updateBlockNumBars(viewModelId: UUID, updatedBlock: Block, numBars: Int) {
    canvasVersion += 1
    let message = BlockNumBarsUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      numBars: numBars)
    messages.append(message)
  }

  func updateBlockStartOffset(viewModelId: UUID, updatedBlock: Block, startOffset: Int) {
    canvasVersion += 1
    let message = BlockStartOffsetUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      startOffset: startOffset)
    messages.append(message)
  }

  func updateBlockVolume(viewModelId: UUID, updatedBlock: Block, volume: Double) {
    canvasVersion += 1
    let message = BlockVolumeUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      volume: volume)
    messages.append(message)
  }

  func updateBlockIsMuted(viewModelId: UUID, updatedBlock: Block, isMuted: Bool) {
    canvasVersion += 1
    let message = BlockIsMutedUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      isMuted: isMuted)
    messages.append(message)
  }
  
  func duplicateBlock(viewModelId: UUID, newBlock: Block) {
    canvasVersion += 1
    let message = BlockDuplicatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      block: newBlock.toDTO())
    messages.append(message)
  }
}
