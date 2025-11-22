//
//  CanvasViewModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Combine
import Foundation
import SwiftUI
import os
import Waveform
import AVFoundation

class CanvasViewModel: ObservableObject {
  private static let logger = Logger(
    subsystem: "ViewModels",
    category: String(describing: Library.self)
  )

  let musicEngine: MusicEngine
  let canvasStore: CanvasStore?
  let sampleSetStore: SampleSetStore?
  let canvasMessageStore: CanvasMessageStore?

  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]
  @Published var allBlockGroups: [BlockGroup]
  @Published var selectedSampleSetName: String = ""
  @Published var canvasSnapshot: UIImage?

  var id: UUID
  var addBlockTapGridPosition: CGPoint?
  var selectedBlock: Block?
  var draggingBlock: Block?
  var selectedBlockGroup: BlockGroup?

  var canvasScrollOffset = CGPoint.zero
  var songNameToLoad: String?

  var blockDetailsViewModel: BlockDetailsViewModel?

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0
  static let canvasWidth: CGFloat = 1000.0
  static let canvasHeight: CGFloat = 1000.0

  /// Calculates the number of dot columns and rows for the canvas background grid.
  /// - Returns: A tuple (cols, rows) representing the number of columns and rows.
  static func gridDimensions() -> (cols: Int, rows: Int) {
    let dotSpacing = blockSize + blockSpacing
    let cols = Int(canvasWidth / dotSpacing)
    let rows = Int(canvasHeight / dotSpacing)
    return (cols, rows)
  }

  /// Calculates the grid spacing used for the background dots and block layout.
  /// - Returns: The spacing between grid points (dot to dot) in points.
  static func gridSpacing() -> CGFloat {
    return blockSize + blockSpacing
  }

  /// Quantizes a given point to the center of the nearest grid square on the canvas.
  /// - Parameter location: The original point in canvas coordinates.
  /// - Returns: A new point snapped to the center of the nearest grid cell.
  static func quantizedPoint(for location: CGPoint) -> CGPoint {
    let spacing = gridSpacing()
    let halfBlock = (blockSize + blockSpacing) / 2.0
    let gridPos = gridPosition(for: location)

    // Convert back to actual canvas coordinates (center of the grid square)
    let quantizedX = (gridPos.x * spacing) + halfBlock
    let quantizedY = (gridPos.y * spacing) + halfBlock

    return CGPoint(x: quantizedX, y: quantizedY)
  }

  static func gridPosition(for location: CGPoint) -> CGPoint {
    let spacing = gridSpacing()

    // Compute grid cell indices
    let col = floor(location.x / spacing)
    let row = floor(location.y / spacing)

    return CGPoint(x: col, y: row)
  }

  private var orienttationCancellable: AnyCancellable?
  private var messagesCancellable: AnyCancellable?
  @Published var isLandscapeOrientation: Bool = UIDevice.current.orientation.isLandscape

  // TODO - consolidate this into CanvasMessageStore
  var canvasVersion = 0

  init(
    canvasModel: CanvasModel,
    musicEngine: MusicEngine,
    canvasStore: CanvasStore?,
    sampleSetStore: SampleSetStore?,
    canvasMessageStore: CanvasMessageStore?,
    songNameToLoad: String? = nil,
    viewModelId: UUID = UUID()
  ) {
    self.id = viewModelId
    self.musicEngine = musicEngine
    self.canvasModel = canvasModel
    self.canvasStore = canvasStore
    self.sampleSetStore = sampleSetStore
    self.canvasMessageStore = canvasMessageStore

    self.allBlocks = []
    self.allBlockGroups = []
    self.canvasModel.musicEngine = musicEngine

    musicEngine.delegate = canvasModel

    orienttationCancellable = NotificationCenter.default
      .publisher(for: UIDevice.orientationDidChangeNotification)
      .sink { _ in
        self.isLandscapeOrientation = UIDevice.current.orientation.isLandscape
      }

    // Observe canvas messages and process when they change
    messagesCancellable = canvasMessageStore?
      .$messages
      .receive(on: DispatchQueue.main)
      .dropFirst()
      .sink { [weak self] messages in
        self?.processCanvasMessages(messages)
      }

    self.updateAllBlocksList()

    self.songNameToLoad = songNameToLoad
  }
}

// Lifecycle Events

extension CanvasViewModel {
  func resetCanvasModel(newCanvasModel: CanvasModel) {
    musicEngine.stop()
    canvasModel.cleanup()

    sampleSetStore?.loadLocalSampleSets()
    canvasModel = newCanvasModel
    canvasModel.library.loadLibraryFrom(libraryFolderName: canvasModel.library.name)
    musicEngine.tempo = canvasModel.library.tempo
    Self.logger.debug("Setting music engine tempo to: \(self.musicEngine.tempo)")
    selectedSampleSetName = canvasModel.library.name

    allBlocks = []
    updateAllBlocksList()
    canvasModel.setMusicEngineAfterLoad(musicEngine: musicEngine)
    musicEngine.reset()
    musicEngine.play()
  }

  func onViewAppear() {
    if songNameToLoad == nil {
      canvasModel.library.loadLibraryFrom(libraryFolderName: "Funk")
      musicEngine.tempo = canvasModel.library.tempo
      selectedSampleSetName = canvasModel.library.name
      sampleSetStore?.loadLocalSampleSets()
      updateAllBlocksList()
    }

    musicEngine.initializeEngine()
    musicEngine.play()

    if let songName = songNameToLoad, let canvasStore = canvasStore {
      if let canvasModel = canvasStore.loadCanvas(name: songName) {
        resetCanvasModel(newCanvasModel: canvasModel)
        songNameToLoad = nil
      }
    }
  }
}

// Canvas messages handling

extension CanvasViewModel {
  private func processCanvasMessages(_ messages: [CanvasMessage]) {
    Self.logger.debug("Received canvas messages: \(messages.count)")

    for message in messages where message.viewModelId != self.id {
      // TODO - add some versioning logic to just process the last message
      if canvasVersion < message.canvasVersion {
        handle(message: message)
        canvasVersion = message.canvasVersion
      }
    }
  }

  private func handle(message: CanvasMessage) {
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
    default:
      break
    }
  }

  private func handleBlockAdded(_ message: BlockAddedMessage) {
    if let newBlockGroupDTO = message.newBlockGroup {
      canvasModel.addBlockGroup(from: newBlockGroupDTO)
      updateAllBlocksList()
    }
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
}


// Events from view interactions

extension CanvasViewModel {
  func loadSampleSetAndResetCanvas(sampleSetName: String) {
    if sampleSetName != canvasModel.library.name {
      let freshCanvasModel = CanvasModel(sampleSetStore: sampleSetStore)
      freshCanvasModel.library.name = sampleSetName
      resetCanvasModel(newCanvasModel: freshCanvasModel)
    }
  }
}

// Block events

extension CanvasViewModel {
  func startBlockDrag(block: Block) {
    block.dragging = true
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    if !block.isLibraryBlock {
      draggingBlock = block
    }
    updateAllBlocksList()

    canvasMessageStore?.disconnectBlockFromGroupMessage(viewModelId: id, updatedBlock: block)
  }

  func updateBlockDragLocation(block: Block, location: CGPoint) {
    if !block.dragging {
      startBlockDrag(block: block)
    }
    block.location = location
  }

  func addBlockToCanvasOnGrid(newBlock: Block) -> Block {
    addBlockTapGridPosition = nil
    newBlock.location = CanvasViewModel.quantizedPoint(for: CGPoint(
      x: newBlock.location.x - canvasScrollOffset.x,
      y: newBlock.location.y - canvasScrollOffset.y))
    newBlock.visible = true

    let (updatedBlock, newBlockGroup) = dropBlockOnCanvasWithNewGroup(block: newBlock)

    canvasMessageStore?.addBlockToCanvasOnGrid(viewModelId: id, newBlock: updatedBlock, newGroup: newBlockGroup)

    return updatedBlock
  }

  func deleteBlockFromCanvas(block: Block) {
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    updateAllBlocksList()

    canvasMessageStore?.deleteBlock(viewModelId: id, deletedBlock: block)
  }

  func dropBlockOnCanvas(block: Block) -> Block {
    let (updatedBlock, newBlockGroup) = dropBlockOnCanvasWithNewGroup(block: block)

    // TODO - figure out if this is an existing block and call add if it is new
    canvasMessageStore?.moveBlock(viewModelId: id, updatedBlock: updatedBlock, newGroup: newBlockGroup)

    return updatedBlock
  }

  func dropBlockOnCanvasWithNewGroup(block: Block) -> (Block, BlockGroup?) {
    let blockWasBeingDragged = block.dragging
    block.dragging = false
    draggingBlock = nil

    var blockDroppedOnCanvas = block
    if block.isLibraryBlock {
      blockDroppedOnCanvas = Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: block.location.x - canvasScrollOffset.x, y: block.location.y - canvasScrollOffset.y),
        color: block.color,
        icon: block.icon,
        visible: true,
        loopURL: block.loopURL,
        relativePath: block.relativePath
      )
    }

    let (_, newBlockGroup) = canvasModel.addBlockToExistingOrNewGroup(block: blockDroppedOnCanvas)

    updateAllBlocksList()

    if blockWasBeingDragged {
      // Animate the block into place
      let adjusted = CGPoint(
        x: blockDroppedOnCanvas.location.x - canvasScrollOffset.x,
        y: blockDroppedOnCanvas.location.y - canvasScrollOffset.y)
      let quantized = CanvasViewModel.quantizedPoint(for: adjusted)
      withAnimation(.spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.2)) {
        blockDroppedOnCanvas.location = quantized
      }
    }

    return (blockDroppedOnCanvas, newBlockGroup)
  }

  func selectBlock(block: Block) {
    selectedBlock = block
    block.isSelected = true
    blockDetailsViewModel = BlockDetailsViewModel(block: block)
  }

  func unselectCurrentlySelectedBlock() {
    if let block = selectedBlock {
      unselectBlock(block: block)
    }
  }

  func unselectBlock(block: Block) {
    selectedBlock = nil
    block.isSelected = false
    blockDetailsViewModel = nil
  }

  func toggleMute(block: Block) {
    block.isMuted.toggle()
    canvasMessageStore?.updateBlockIsMuted(viewModelId: id, updatedBlock: block, isMuted: block.isMuted)
  }

  // New updates for details sheet

  func update(startOffset: Int, for block: Block) {
    block.blockGroup?.updateBlockStartOffset(block: block, newStartOffset: startOffset)
    canvasMessageStore?.updateBlockStartOffset(viewModelId: id, updatedBlock: block, startOffset: startOffset)
  }

  func update(volume: Double, for block: Block) {
    let clamped = max(0.0, min(1.0, volume))
    block.volume = clamped
    canvasMessageStore?.updateBlockVolume(viewModelId: id, updatedBlock: block, volume: clamped)
  }

  func update(numBars: Int, for block: Block) {
    block.blockGroup?.updateBlockNumBars(block: block, newNumBars: numBars)
    canvasMessageStore?.updateBlockNumBars(viewModelId: id, updatedBlock: block, numBars: numBars)
  }

  /// Decrement the number of bars for a block by 1 with clamping to [1, block.maxNumBars]
  func decrementNumBars(for block: Block) {
    update(numBars: block.numBars - 1, for: block)
  }

  /// Increment the number of bars for a block by 1 with clamping to [1, block.maxNumBars]
  func incrementNumBars(for block: Block) {
    update(numBars: block.numBars + 1, for: block)
  }

  /// Decrement the start offset for a block by 1 with clamping to [0, (block.maxNumBars) - 1]
  func decrementStartOffset(for block: Block) {
    update(startOffset: block.startOffset - 1, for: block)
  }

  /// Increment the start offset for a block by 1 with clamping to [0, (block.maxNumBars) - 1]
  func incrementStartOffset(for block: Block) {
    update(startOffset: block.startOffset + 1, for: block)
  }

  @discardableResult
  func duplicate(block: Block) -> Block {
    // TODO - move this logic into CanvasModel

    // Attempt to place to the right by one grid
    let spacing = CanvasViewModel.gridSpacing()
    let newLocation = CGPoint(x: block.location.x + spacing, y: block.location.y)
    let newBlock = block.instantiateCopyWith(location: newLocation, isLibraryBlock: false)
    newBlock.visible = true
    let (updatedBlock, _) = dropBlockOnCanvasWithNewGroup(block: newBlock)

    canvasMessageStore?.duplicateBlock(viewModelId: id, newBlock: block)
    return updatedBlock
  }
}

// Block Group events
extension CanvasViewModel {
  func selectBlockGroup(group: BlockGroup) {
    // Unselect any previously selected group
    if let prev = selectedBlockGroup, prev.id != group.id {
      unselectBlockGroup(group: prev)
    }
    selectedBlockGroup = group
    group.isSelected = true
    for block in group.allBlocks { block.isSelected = true }
  }

  func unselectCurrentlySelectedBlockGroup() {
    if let group = selectedBlockGroup {
      unselectBlockGroup(group: group)
    }
  }

  func unselectBlockGroup(group: BlockGroup) {
    if selectedBlockGroup?.id == group.id { selectedBlockGroup = nil }
    group.isSelected = false
    for block in group.allBlocks { block.isSelected = false }
  }

  func startBlockGroupDrag(blockGroup: BlockGroup) {
    canvasMessageStore?.startMoveBlockGroup(viewModelId: id, blockGroupId: blockGroup.id)
  }


  func updateBlockGroupDragLocation(blockGroup: BlockGroup, location: CGPoint) {
    if !blockGroup.isDragging {
      blockGroup.isDragging = true
      startBlockGroupDrag(blockGroup: blockGroup)
    }

    // Move the entire group's blocks by the delta from the left-most block anchor
    guard let anchor = blockGroup.leftMostBlock?.location else { return }

    let deltaX = location.x - anchor.x
    let deltaY = location.y - anchor.y

    for block in blockGroup.allBlocks {
      block.location = CGPoint(x: block.location.x + deltaX, y: block.location.y + deltaY)
    }

    updateAllBlocksList()
  }

  @discardableResult
  func dropBlockGroupOnCanvas(blockGroup: BlockGroup) -> BlockGroup {
    blockGroup.isDragging = false

    // Quantize all blocks in the group to the grid on drop, similar to single-block behavior
    withAnimation(.spring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.2)) {
      for block in blockGroup.allBlocks {
        let adjusted = CGPoint(
          x: block.location.x - canvasScrollOffset.x,
          y: block.location.y - canvasScrollOffset.y)
        let quantized = CanvasViewModel.quantizedPoint(for: adjusted)
        block.location = quantized
      }
    }

    updateAllBlocksList()

    canvasMessageStore?.moveBlockGroup(viewModelId: id, blockGroup: blockGroup)

    return blockGroup
  }

  func update(volume: Double, for group: BlockGroup) {
    let clamped = max(0.0, min(1.0, volume))
    group.volume = clamped
    for block in group.allBlocks {
      update(volume: clamped, for: block)
    }
  }

  /// Toggles mute state for all blocks in the given group.
  /// If any block is currently unmuted, mutes all; otherwise, unmutes all.
  func toggleMute(blockGroup group: BlockGroup) {
    let shouldMute = group.allBlocks.contains { !$0.isMuted }
    for block in group.allBlocks {
      if block.isMuted != shouldMute {
        toggleMute(block: block)
      }
    }
  }

  /// Creates a duplicate of all blocks in the group, offset to the right by one grid spacing, and returns the new group.
  @discardableResult
  func duplicate(blockGroup group: BlockGroup) -> BlockGroup? {
    // Compute an offset of one grid spacing in X
    let spacing = CanvasViewModel.gridSpacing()

    // Create copies of each block shifted by spacing
    var newBlocks: [Block] = []
    for block in group.allBlocks {
      let newLocation = CGPoint(x: block.location.x + spacing, y: block.location.y)
      let copy = block.instantiateCopyWith(location: newLocation, isLibraryBlock: false)
      copy.visible = true
      newBlocks.append(copy)
    }

    // Place first block to start a new group
    guard let first = newBlocks.first else { return nil }
    let droppedFirst = dropBlockOnCanvas(block: first)

    // Add remaining blocks to that new or existing group via normal drop logic
    for block in newBlocks.dropFirst() {
      _ = dropBlockOnCanvas(block: block)
    }

    // Find and return the new group (the group containing droppedFirst)
    return droppedFirst.blockGroup
  }

  func delete(blockGroup group: BlockGroup) {
    // Remove all blocks in this group from the canvas
    for block in group.allBlocks { deleteBlockFromCanvas(block: block) }
    updateAllBlocksList()
  }
}

// Canvas managmeent events

extension CanvasViewModel {
  func clearCanvas() {
    canvasModel.clear()
    updateAllBlocksList()
  }

  func renameSong(newName: String, thunbnail: UIImage?) {
    canvasModel.name = newName
    canvasModel.thumnail = thunbnail

    saveSong()
  }

  func saveSong() {
    canvasStore?.saveCanvas(canvasModel: canvasModel)
  }

  func loadSong() {
    if let canvasStore = canvasStore, let canvasModel = canvasStore.loadCanvas(name: canvasModel.name) {
      resetCanvasModel(newCanvasModel: canvasModel)
    }
  }
}

// Sampleset managmeent events

extension CanvasViewModel {
  func downloadRemoteSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    sampleSetStore?.downloadRemoteSampleSet(remoteSampleSet)
  }

  func removeLocalSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    if selectedSampleSetName != remoteSampleSet.remoteSampleSet.name {
      sampleSetStore?.removeLocalSampleSet(remoteSampleSet)
    }
  }
}

// Thumbnail capture funcnationality

extension CanvasViewModel {
  func getThumbnailFromScreenShot(screenShotImage: CGImage?) -> UIImage? {
    let blockBounds = getSquareBoundsAroundCanvasBlocks()
    if let croppedImage = screenShotImage?.cropping(to: blockBounds) {
      let croppedUIImage = UIImage(cgImage: croppedImage)
      let thumbSize = CGSize(width: 70, height: 70) // TODO - move these to constants somewhere
      let renderer = UIGraphicsImageRenderer(size: thumbSize)
      return renderer.image { _ in
        croppedUIImage.draw(in: CGRect(origin: .zero, size: thumbSize))
      }
    }
    return nil
  }

  func getSquareBoundsAroundCanvasBlocks() -> CGRect {
    var minX: CGFloat = CanvasViewModel.canvasWidth
    var minY: CGFloat = CanvasViewModel.canvasHeight
    var maxX: CGFloat = 0
    var maxY: CGFloat = 0

    for block in allBlocks {
      if block.location.x < minX {
        minX = block.location.x
      }
      if block.location.y < minY {
        minY = block.location.y
      }
      if block.location.x > maxX {
        maxX = block.location.x
      }
      if block.location.y > maxY {
        maxY = block.location.y
      }
    }

    let margin = CanvasViewModel.blockSize
    minX -= margin
    minY -= margin
    maxX += margin
    maxY += margin

    var xLoc = minX
    var yLoc = minY
    var width = maxX - minX
    var height = maxY - minY

    // Turn the bounds into a square and center
    if width > height {
      yLoc -= (width - height) / 2
      height = width
    } else {
      xLoc -= (height - width) / 2
      width = height
    }

    // Make sure bounds is not off the canvas
    if xLoc < 0 {
      xLoc = 0
    }
    if xLoc + width > CanvasViewModel.canvasWidth {
      xLoc -= xLoc + width - CanvasViewModel.canvasWidth
    }

    if yLoc < 0 {
      yLoc = 0
    }
    if yLoc + height > CanvasViewModel.canvasHeight {
      yLoc -= yLoc + height - CanvasViewModel.canvasHeight
    }

    return CGRect(x: xLoc, y: yLoc, width: width, height: height)
  }
}

// Internal State Managment

extension CanvasViewModel {
  func updateAllBlocksList() {
    canvasModel.blocksGroups.sort { $0.id.uuidString > $1.id.uuidString }
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + [draggingBlock].compactMap { $0 }

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList
    allBlockGroups = canvasModel.blocksGroups
  }
}

// Details View Model

extension AVAudioFile {
  /// converts to Swift friendly Float array
  public func toFloatChannelData2() -> [[Float]]? {
    guard let pcmBuffer = toAVAudioPCMBuffer(),
          let data = pcmBuffer.toFloatChannelData() else { return nil }
    return data
  }
}

class BlockDetailsViewModel: ObservableObject {
  private static let logger = Logger(
    subsystem: "ViewModels",
    category: String(describing: Library.self)
  )

  var samples: SampleBuffer
  let block: Block

  init(block: Block) {
    self.block = block
    samples = SampleBuffer(samples: [])
    do {
      if let loopUrl = block.loopURL {
        let file = try AVAudioFile(forReading: loopUrl)
        updateWaveform(file: file)
      }
    } catch let error {
      Self.logger.error("LoopDetailsViewModel.setBlock() error: \(error)")
    }
  }

  func updateWaveform(file: AVAudioFile) {
    let stereo = file.toFloatChannelData2()!
    samples = SampleBuffer(samples: stereo[0])
  }
}

