//
//  CanvasMessageStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/16/25.
//

import Combine
import Foundation
import GroupActivities
import os

protocol CanvasMessage: Codable {
  var canvasVersion: Int { get }
  var viewModelId: UUID { get }
}

class CanvasMessageStore: GroupSessionWrapperDelegate, ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasMessageStore.self)
  )

  // Message State
  @Published var messages: [CanvasMessage]

  var groupSessionWrapper: GroupSessionWrapper?

  // Share Play Properties
  @Published var groupSession: GroupSession<LoopCanvasSession>?
  private var messenger: GroupSessionMessenger?
  private var sessionTasks = Set<Task<Void, Never>>()
  private var sessionCancellables = Set<AnyCancellable>()

  init(groupSessionWrapper: GroupSessionWrapper? = nil) {
    self.messages = []

    self.groupSessionWrapper = groupSessionWrapper
    self.groupSessionWrapper?.delegate = self

    self.groupSessionWrapper?.observeLoopCanvasSessions()
  }

  func receive(_ message: any CanvasMessage) {
    messages.append(message)
  }

  func send(_ message: any CanvasMessage) {
    groupSessionWrapper?.send(message)
  }

  func startSharing() {
    self.groupSessionWrapper?.startSharing()
  }
}

struct LoopCanvasSession: GroupActivity {
  var metadata: GroupActivityMetadata {
    var metadata = GroupActivityMetadata()
    metadata.title = "LoopCanvas Jam"
    metadata.type = .generic
    return metadata
  }
}

protocol GroupSessionWrapperDelegate {
  func receive(_ message: CanvasMessage)
}

protocol GroupSessionWrapper: ObservableObject {
  func observeLoopCanvasSessions()
  func startSharing()
  func teardownSession()
  func send(_ message: any CanvasMessage)
  var delegate: GroupSessionWrapperDelegate? { get set }
}

class ConcreteGroupSessionWrapper: @MainActor GroupSessionWrapper, ObservableObject {
  var delegate: GroupSessionWrapperDelegate?

  // Share Play Properties
  var groupSession: GroupSession<LoopCanvasSession>?
  private var messenger: GroupSessionMessenger?
  private var sessionTasks = Set<Task<Void, Never>>()
  private var sessionCancellables = Set<AnyCancellable>()
  private var canvasVersion: Int = 0  // increments on major changes

  func observeLoopCanvasSessions() {
    Task {
      for await session in LoopCanvasSession.sessions() {
        await MainActor.run {
          self.configureGroupSession(session)
        }
        session.join()
      }
    }
  }

  @MainActor
  func configureGroupSession(_ session: GroupSession<LoopCanvasSession>) {
    // Clean up any existing session
    teardownSession()

    groupSession = session
    let messenger = GroupSessionMessenger(session: session)
    self.messenger = messenger

    // 1) Listen for block messages
    sessionTasks.insert(Task {
      for await (message, _) in messenger.messages(of: BlockAddedMessage.self) {
        await MainActor.run { self.delegate?.receive(message) }
      }
    })

    sessionTasks.insert(Task {
      for await (message, _) in messenger.messages(of: BlockMovedMessage.self) {
        await MainActor.run { self.delegate?.receive(message) }
      }
    })

    // ... add similar tasks for other message types ...

    //    sessionTasks.insert(Task {
    //      for await (message, _) in messenger.messages(of: LoopCanvasSnapshotMessage.self) {
    //        await MainActor.run { self.receive(message) }
    //      }
    //    })

    // 2) Watch for new participants to send snapshots to
    //    session.$activeParticipants
    //      .sink { [weak self, weak session] participants in
    //        guard let self, let session else { return }
    //        self.handleActiveParticipantsChanged(participants, in: session)
    //      }
    //      .store(in: &sessionCancellables)
  }

  @MainActor
  func teardownSession() {
    messenger = nil
    groupSession = nil
    sessionTasks.forEach { $0.cancel() }
    sessionTasks.removeAll()
    sessionCancellables.removeAll()
  }

  func startSharing() {
    Task {
      do {
        _ = try await LoopCanvasSession().activate()
      } catch {
        print("Failed to start LoopCanvasSession: \(error)")
      }
    }
  }

  func send(_ message: any CanvasMessage) {
    Task {
      do {
        try await messenger?.send(message)
      } catch {
        print("Failed to send BlockMovedMessage: \(error)")
      }
    }
  }
}

class MockGroupSessionWrapper: @MainActor GroupSessionWrapper, ObservableObject {
  var delegate: GroupSessionWrapperDelegate?

  var linkedMockGroupSessionWrapper: MockGroupSessionWrapper?
  var messageQueue: [any CanvasMessage] = []

  func observeLoopCanvasSessions() {
  }

  func startSharing() {
  }

  func teardownSession() {
  }

  func send(_ message: any CanvasMessage) {
    messageQueue.append(message)
  }

  func recieve(_ message: any CanvasMessage) {
    delegate?.receive(message)
  }

  func debugBroadCastMessages() {
    for message in messageQueue {
      linkedMockGroupSessionWrapper?.recieve(message)
    }
    messageQueue = []
  }
}


// Messages

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

struct BlockGroupStartedMoveMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockGroupId: UUID
}

struct BlockGroupMovedMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  let blockGroupId: UUID
  let updatedBlockLocations: [UUID: CGPoint]
}

extension CanvasMessageStore {
  func addBlockToCanvasOnGrid(viewModelId: UUID, canvasVersion: Int, newBlock: Block, newGroup: BlockGroup?) {
    let message = BlockAddedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      block: newBlock.toDTO(),
      newBlockGroup: newGroup?.toDTO())
    send(message)
  }

  func disconnectBlockFromGroupMessage(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block) {
    let message = BlockDisconnectedFromGroupMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      updatedBlock: updatedBlock.toDTO())
    send(message)
  }

  func moveBlock(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block, newGroup: BlockGroup?) {
    let message = BlockMovedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      updatedBlock: updatedBlock.toDTO(),
      newBlockGroup: newGroup?.toDTO())
    send(message)
  }

  func deleteBlock(viewModelId: UUID, canvasVersion: Int, deletedBlock: Block) {
    let message = BlockDeteledMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      deletedBlock: deletedBlock.toDTO())
    send(message)
  }

  func updateBlockNumBars(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block, numBars: Int) {
    let message = BlockNumBarsUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      numBars: numBars)
    send(message)
  }

  func updateBlockStartOffset(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block, startOffset: Int) {
    let message = BlockStartOffsetUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      startOffset: startOffset)
    send(message)
  }

  func updateBlockVolume(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block, volume: Double) {
    let message = BlockVolumeUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      volume: volume)
    send(message)
  }

  func updateBlockIsMuted(viewModelId: UUID, canvasVersion: Int, updatedBlock: Block, isMuted: Bool) {
    let message = BlockIsMutedUpdatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockId: updatedBlock.id,
      isMuted: isMuted)
    send(message)
  }

  func duplicateBlock(viewModelId: UUID, canvasVersion: Int, newBlock: Block) {
    let message = BlockDuplicatedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      block: newBlock.toDTO())
    send(message)
  }

  func startMoveBlockGroup(viewModelId: UUID, canvasVersion: Int, blockGroupId: UUID) {
    let message = BlockGroupStartedMoveMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockGroupId: blockGroupId)
    send(message)
  }

  func moveBlockGroup(viewModelId: UUID, canvasVersion: Int, blockGroup: BlockGroup) {
    let message = BlockGroupMovedMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      blockGroupId: blockGroup.id,
      updatedBlockLocations: Dictionary(
        uniqueKeysWithValues: blockGroup.allBlocks.map { ( $0.id, $0.location) }))
    send(message)
  }
}
