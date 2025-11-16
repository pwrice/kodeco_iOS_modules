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
}

struct BlockAddedMessage: CanvasMessage {
  var canvasVersion: Int
  let block: BlockDTO
  let newBlockGroup: BlockGroupDTO?
}

struct BlockMovedMessage: CanvasMessage {
  var canvasVersion: Int
  let blockID: Int
  let newLocation: CGPoint
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

  func addBlockToCanvasOnGrid(newBlock: Block, newGroup: BlockGroup?) {
    canvasVersion += 1
    let message = BlockAddedMessage(
      canvasVersion: canvasVersion,
      block: newBlock.toDTO(),
      newBlockGroup: newGroup?.toDTO())
    messages.append(message)
  }
}
