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
}
