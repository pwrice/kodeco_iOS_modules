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
  static let logger = Logger(
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
  @Published var isPlaying: Bool = false

  var id: UUID
  var addBlockTapGridPosition: CGPoint?
  var selectedBlock: Block?
  var draggingBlock: Block?
  var selectedBlockGroup: BlockGroup?

  var canvasScrollOffset = CGPoint.zero
  var songNameToLoad: String?

  var blockDetailsViewModel: BlockDetailsViewModel?

  var canvasTitle: String {
    canvasModel.library.name
  }

  var canvasBPM: String {
    String(canvasModel.library.tempo)
  }

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

  @Published var isLandscapeOrientation: Bool = UIDevice.current.orientation.isLandscape

  // Increment this everytime a canvas mutation is made that needs to be synced via
  // CanvasMessageStore and SharePlay to other devices.
  @Published var canvasVersion = 0
  @Published var mySharePlayUser: SharePlayUser?
  @Published var sharePlayUsers: [SharePlayUser]?
  @Published var sharePlayHostUserId: UUID?

  var subscriptions = Set<AnyCancellable>()

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

    NotificationCenter.default
      .publisher(for: UIDevice.orientationDidChangeNotification)
      .sink { _ in
        self.isLandscapeOrientation = UIDevice.current.orientation.isLandscape
      }
      .store(in: &subscriptions)

    // Observe canvas messages and process when they change
    canvasMessageStore?
      .$messages
      .receive(on: DispatchQueue.main)
      .dropFirst()
      .sink { [weak self] messages in
        self?.processCanvasMessages(messages)
      }
      .store(in: &subscriptions)

    canvasMessageStore?
      .$sharePlayUsers
      .receive(on: DispatchQueue.main)
      .dropFirst()
      .sink { [weak self] sharePlayUsers in
        self?.handleSharePlayUsersUpdated(sharePlayUsers)
      }
      .store(in: &subscriptions)

    canvasMessageStore?
      .$mySharePlayUser
      .receive(on: DispatchQueue.main)
      .dropFirst()
      .sink { [weak self] mySharePlayUser in
        self?.handleMySharePlayUsersUpdated(mySharePlayUser)
      }
      .store(in: &subscriptions)

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
    isPlaying = true
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
    isPlaying = true

    if let songName = songNameToLoad, let canvasStore = canvasStore {
      if let canvasModel = canvasStore.loadCanvas(name: songName) {
        resetCanvasModel(newCanvasModel: canvasModel)
        songNameToLoad = nil
      }
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


// Canvas managmeent events

extension CanvasViewModel {
  // Play Controls

  func startCanvasPlayback() {
    musicEngine.play()
    isPlaying = true
  }

  func pauseCanvasPlayback() {
    musicEngine.stop()
    isPlaying = false
  }

  func togglePlayback() {
    if isPlaying {
      pauseCanvasPlayback()
    } else {
      startCanvasPlayback()
    }
  }


  func clearCanvas() {
    canvasModel.clear()
    updateAllBlocksList()
  }

  func renameSong(newName: String, thunbnail: UIImage?) {
    canvasModel.name = newName
    canvasModel.thumnail = thunbnail

    saveSong()
  }

  func sendCanvasModelSnapshot() {
    if let sharePlayHostUserId {
      canvasVersion += 1
      canvasMessageStore?.canvasModelSnapShot(
        viewModelId: id, canvasVersion: canvasVersion, hostUserId: sharePlayHostUserId, canvasModel: canvasModel)
    }
  }

  func resetSharePlaySession() {
    canvasMessageStore?.resetSession()
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

