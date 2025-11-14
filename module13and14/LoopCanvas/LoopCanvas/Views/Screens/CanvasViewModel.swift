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

  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]
  @Published var selectedSampleSetName: String = ""
  @Published var canvasSnapshot: UIImage?

  var addBlockTapGridPosition: CGPoint?
  var selectedBlock: Block?
  var draggingBlock: Block?
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
  @Published var isLandscapeOrientation: Bool = UIDevice.current.orientation.isLandscape

  init(
    canvasModel: CanvasModel,
    musicEngine: MusicEngine,
    canvasStore: CanvasStore?,
    sampleSetStore: SampleSetStore?,
    songNameToLoad: String? = nil
  ) {
    self.musicEngine = musicEngine
    self.canvasModel = canvasModel
    self.canvasStore = canvasStore
    self.sampleSetStore = sampleSetStore

    self.allBlocks = []
    self.canvasModel.musicEngine = musicEngine
    musicEngine.delegate = canvasModel

    orienttationCancellable = NotificationCenter.default
      .publisher(for: UIDevice.orientationDidChangeNotification)
      .sink { _ in
        self.isLandscapeOrientation = UIDevice.current.orientation.isLandscape
      }

    self.updateAllBlocksList()

    self.songNameToLoad = songNameToLoad
  }

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
}

// Events from views

extension CanvasViewModel {
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

  func updateBlockDragLocation(block: Block, location: CGPoint) {
    if !block.dragging {
      startBlockDrag(block: block)
    }
    block.location = location
  }

  func startBlockDrag(block: Block) {
    block.dragging = true
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    if !block.isLibraryBlock {
      draggingBlock = block
    }
    updateAllBlocksList()
  }

  func addBlockToCanvasOnGrid(block: Block) -> Block {
    addBlockTapGridPosition = nil
    block.location = CanvasViewModel.quantizedPoint(for: CGPoint(
      x: block.location.x - canvasScrollOffset.x,
      y: block.location.y - canvasScrollOffset.y))
    block.visible = true
    return dropBlockOnCanvas(block: block)
  }

  func deleteBlockFromCanvas(block: Block) {
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    updateAllBlocksList()
  }

  func dropBlockOnCanvas(block: Block) -> Block {
    // TODO - break this function up and refator logic into Canvas Model

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

    let blockAddedToGroup = canvasModel.checkBlockPositionAndAddToAvailableGroup(block: blockDroppedOnCanvas)

    if !blockAddedToGroup {
      canvasModel.addBlockGroup(initialBlock: blockDroppedOnCanvas)
    }

    updateAllBlocksList()

    return blockDroppedOnCanvas
  }

  func loadSampleSetAndResetCanvas(sampleSetName: String) {
    if sampleSetName != canvasModel.library.name {
      let freshCanvasModel = CanvasModel(sampleSetStore: sampleSetStore)
      freshCanvasModel.library.name = sampleSetName
      resetCanvasModel(newCanvasModel: freshCanvasModel)
    }
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
  }

  func update(numBars: Int, for block: Block) {
    block.numBars = numBars
    // TODO - adjust block group
  }

  // New updates for details sheet

  func update(startOffset: Int, for block: Block) {
    let maxBeats = max(0, (block.maxNumBars * 4) - 1)
    let clamped = max(0, min(maxBeats, startOffset))
    block.startOffset = clamped
  }

  func update(volume: Double, for block: Block) {
    let clamped = max(0.0, min(1.0, volume))
    block.volume = clamped
  }

  @discardableResult
  func duplicate(block: Block) -> Block {
    // Attempt to place to the right by one grid
    let spacing = CanvasViewModel.gridSpacing()
    let newLocation = CGPoint(x: block.location.x + spacing, y: block.location.y)
    let newBlock = block.instantiateCopyWith(location: newLocation, isLibraryBlock: false)
    newBlock.visible = true
    return dropBlockOnCanvas(block: newBlock)
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
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + [draggingBlock].compactMap { $0 }

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList
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
