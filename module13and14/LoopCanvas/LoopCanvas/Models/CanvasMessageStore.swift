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

struct SharePlayUser: Codable, Equatable {
  let id: UUID
  let name: String = "Anonymous"
}

class CanvasMessageStore: GroupSessionWrapperDelegate, ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: CanvasMessageStore.self)
  )

  @Published var sharePlayUsers: [SharePlayUser]
  @Published var mySharePlayUser: SharePlayUser?
  @Published var eligibleToStartSharing = false
  @Published var sharePlaySessionActive = false

  // Message State
  @Published var messages: [CanvasMessage]

  var groupSessionWrapper: GroupSessionWrapper?

  private var messenger: GroupSessionMessenger?
  private var sessionTasks = Set<Task<Void, Never>>()
  private var sessionCancellables = Set<AnyCancellable>()

  init(groupSessionWrapper: GroupSessionWrapper? = nil) {
    self.sharePlayUsers = []
    self.messages = []

    self.groupSessionWrapper = groupSessionWrapper
    self.groupSessionWrapper?.delegate = self

    self.groupSessionWrapper?.observeLoopCanvasSessions()
  }

  func startSharing() {
    self.groupSessionWrapper?.startSharing()
  }

  func resetSession() {
    self.groupSessionWrapper?.reset()
  }

  func receive(_ message: any CanvasMessage) {
    messages.append(message)
  }

  func send(_ message: any CanvasMessage) {
    groupSessionWrapper?.send(message)
  }

  func setLocalSharePlayUser(user: SharePlayUser) {
    mySharePlayUser = user
  }

  func activeParticipantsChanged(sharePlayUsers: [SharePlayUser]) {
    self.sharePlayUsers = sharePlayUsers
  }

  func setEligableToStartSharing(_ eligble: Bool) {
    eligibleToStartSharing = eligble && groupSessionWrapper?.hasActiveSession() == false
  }

  func setHasActiveSession(_ activeSession: Bool) {
    sharePlaySessionActive = activeSession
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

protocol GroupSessionWrapperDelegate: AnyObject {
  func receive(_ message: CanvasMessage)
  func activeParticipantsChanged(sharePlayUsers: [SharePlayUser])
  func setLocalSharePlayUser(user: SharePlayUser)
  func setEligableToStartSharing(_: Bool)
  func setHasActiveSession(_: Bool)
}

protocol GroupSessionWrapper: ObservableObject {
  func observeLoopCanvasSessions()
  func startSharing()
  func reset()
  func teardownSession()
  func send(_ message: any CanvasMessage)
  func hasActiveSession() -> Bool
  var delegate: GroupSessionWrapperDelegate? { get set }
}

class ConcreteGroupSessionWrapper: @MainActor GroupSessionWrapper, ObservableObject {
  var delegate: GroupSessionWrapperDelegate?

  // Share Play Properties
  var groupSession: GroupSession<LoopCanvasSession>?
  @Published var groupStateObserver = GroupStateObserver()
  private var messenger: GroupSessionMessenger?
  private var sessionTasks = Set<Task<Void, Never>>()
  private var sessionCancellables = Set<AnyCancellable>()
  private var canvasVersion: Int = 0  // increments on major changes

  func observeLoopCanvasSessions() {
    $groupStateObserver
      .sink { [weak self] groupState in
        guard let self else { return }
        Task { @MainActor in
          self.delegate?.setEligableToStartSharing(groupState.isEligibleForGroupSession)
        }
      }
      .store(in: &sessionCancellables)

    Task {
      for await session in LoopCanvasSession.sessions() {
        await MainActor.run {
          self.configureGroupSession(session)
        }
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

    self.delegate?.setLocalSharePlayUser(user: SharePlayUser(id: session.localParticipant.id))

    session.$state
      .sink { state in
        if case .invalidated = state {
          self.groupSession = nil
          self.reset()
        }
      }
      .store(in: &sessionCancellables)


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

    sessionTasks.insert(Task {
      for await (message, _) in messenger.messages(of: CanvasModelSnapshotMessage.self) {
        await MainActor.run { self.delegate?.receive(message) }
      }
    })

    // 2) Watch for new participants to send snapshots to
    session.$activeParticipants
      .sink { [weak self] participants in
        guard let self else { return }
        Task { @MainActor in
          let users = Array(participants).map { SharePlayUser(id: $0.id) }
          self.delegate?.activeParticipantsChanged(sharePlayUsers: users)
        }
      }
      .store(in: &sessionCancellables)

    session.join()

    delegate?.setHasActiveSession(true)
  }

  @MainActor
  func reset() {
    if groupSession != nil {
      groupSession?.leave()
      groupSession = nil
      self.startSharing()
      delegate?.setHasActiveSession(false)
    }
    messenger = nil
    groupSession = nil
    sessionTasks.forEach { $0.cancel() }
    sessionTasks.removeAll()
    sessionCancellables.removeAll()
  }

  // TODO - combine this w/ above
  @MainActor
  func teardownSession() {
    if groupSession != nil {
      groupSession?.leave()
      groupSession = nil
      delegate?.setHasActiveSession(false)
    }
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

  func hasActiveSession() -> Bool {
    return groupSession == nil
  }
}

class MockGroupSessionWrapper: @MainActor GroupSessionWrapper, ObservableObject {
  var delegate: GroupSessionWrapperDelegate?

  var linkedMockGroupSessionWrapper: MockGroupSessionWrapper?
  var messageQueue: [any CanvasMessage] = []
  var activeSession = false

  func observeLoopCanvasSessions() {
  }

  func startSharing() {
    // would trigger an update that would eventually call configureGroupSession() above
    // and setup the current session
    activeSession = true
  }

  func teardownSession() {
  }

  func send(_ message: any CanvasMessage) {
    messageQueue.append(message)
  }

  func recieve(_ message: any CanvasMessage) {
    delegate?.receive(message)
  }

  func hasActiveSession() -> Bool {
    return activeSession
  }

  func reset() {
  }

  func debugBroadCastMessages() {
    for message in messageQueue {
      linkedMockGroupSessionWrapper?.recieve(message)
    }
    messageQueue = []
  }

  func debugClearMessageQueue() {
    messageQueue = []
  }

  func debugSetLocalSharePlayUser(user: SharePlayUser) {
    self.delegate?.setLocalSharePlayUser(user: user)
  }

  func debugUpdateActiveParticipans(users: [SharePlayUser]) {
    self.delegate?.activeParticipantsChanged(sharePlayUsers: users)
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

struct CanvasModelSnapshotMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  var hostUserId: UUID
  let canvasModel: CanvasModelDTO
}

// Sent when a user becomes a host
struct SetHostMessage: CanvasMessage {
  var canvasVersion: Int
  var viewModelId: UUID
  var sharePlayUser: UUID
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

  func canvasModelSnapShot(viewModelId: UUID, canvasVersion: Int, hostUserId: UUID, canvasModel: CanvasModel) {
    let message = CanvasModelSnapshotMessage(
      canvasVersion: canvasVersion,
      viewModelId: viewModelId,
      hostUserId: hostUserId,
      canvasModel: canvasModel.toDTO())
    send(message)
  }
}
