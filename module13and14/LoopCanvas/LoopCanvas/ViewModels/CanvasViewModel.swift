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
import UIKit
import CoreGraphics

enum InputTool: String, CaseIterable, Identifiable {
  case loop
  case effects
  case visuals

  var id: String { rawValue }

  var label: String {
    switch self {
    case .loop: return "Loop"
    case .effects: return "Effects"
    case .visuals: return "Visuals"
    }
  }

  var systemImage: String {
    switch self {
    case .loop: return "square.grid.3x3.fill" // represents placing blocks on grid
    case .effects: return "paintbrush.pointed" // represents painting effects
    case .visuals: return "sparkles.rectangle.stack" // represents visuals/overlays
    }
  }
}

enum CanvasEffect: String, CaseIterable, Identifiable, Codable {
  case filterDelay
  case highPassFlanger
  case washVerbEcho
  case rhythmicFlangeBandpass
  case resonantSweep
  case tapeEcho
  case gatedVerb
  case subDrop

  var id: String { rawValue }

  var label: String {
    switch self {
    case .filterDelay: return "Filter + Delay"
    case .highPassFlanger: return "HighPass + Flanger"
    case .washVerbEcho: return "Wash Verb + Echo"
    case .rhythmicFlangeBandpass: return "Rhythmic Flange + Bandpass"
    case .resonantSweep: return "Resonant Sweep"
    case .tapeEcho: return "Tape Echo"
    case .gatedVerb: return "Gated Verb"
    case .subDrop: return "Sub Drop"
    }
  }

  var systemImage: String {
    switch self {
    case .filterDelay:
      // Low-pass sweep + delay
      return "slider.horizontal.3"
    case .highPassFlanger:
      // HP sweep with modulation
      return "waveform.path"
    case .washVerbEcho:
      // Lush space + echoes
      return "sparkles"
    case .rhythmicFlangeBandpass:
      // Rhythmic modulation/band movement
      return "metronome"
    case .resonantSweep:
      // Resonant sweeping filter
      return "dot.radiowaves.up.forward"
    case .tapeEcho:
      // Tape/echo vibe
      return "cassette"
    case .gatedVerb:
      // Gated reverb feel
      return "gate"
    case .subDrop:
      // Sub/low-end emphasis
      return "arrow.down.to.line.compact"
    }
  }

  var color: Color {
    switch self {
    case .filterDelay: return Color.blue
    case .highPassFlanger: return Color.cyan
    case .washVerbEcho: return Color.purple
    case .rhythmicFlangeBandpass: return Color.orange
    case .resonantSweep: return Color.mint
    case .tapeEcho: return Color.brown
    case .gatedVerb: return Color.indigo
    case .subDrop: return Color.teal
    }
  }

  // Bridge to the engine's XY modes for unified control
  var xyMode: EffectsRack.XYMode {
    switch self {
    case .filterDelay: return .filterDelay
    case .highPassFlanger: return .highPassFlanger
    case .washVerbEcho: return .washVerbEcho
    case .rhythmicFlangeBandpass: return .rhythmicFlangeBandpass
    case .resonantSweep: return .resonantSweep
    case .tapeEcho: return .tapeEcho
    case .gatedVerb: return .gatedVerb
    case .subDrop: return .subDrop
    }
  }
}

struct EffectStroke: Identifiable, Codable {
  struct EffectPoint: Codable, Hashable {
    var position: CGPoint
    var radius: CGFloat
  }

  let id: UUID
  var effect: CanvasEffect
  var points: [EffectPoint]
  var color: ColorCodable
  var lineWidth: CGFloat
  var opacity: Double

  init(id: UUID = UUID(), effect: CanvasEffect = .filterDelay, points: [EffectPoint] = [], color: Color = .blue, lineWidth: CGFloat = 8, opacity: Double = 0.8) {
    self.id = id
    self.effect = effect
    self.points = points
    self.color = ColorCodable(color)
    self.lineWidth = lineWidth
    self.opacity = opacity
  }

  var colorValue: Color { color.color }
}

// Helper to encode/decode Color
struct ColorCodable: Codable {
  var red: Double
  var green: Double
  var blue: Double
  var alpha: Double

  init(_ color: Color) {
    let uiColor = UIColor(color)
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    self.red = Double(red)
    self.green = Double(green)
    self.blue = Double(blue)
    self.alpha = Double(alpha)
  }

  var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }
}

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
  @Published var isPlaying = false

  var visibleEffectsRect: CGRect = .zero
  @Published var effectStrokes: [EffectStroke] = []
  @Published var currentEffectStroke: EffectStroke?

  @Published var availableEffects: [CanvasEffect] = CanvasEffect.allCases
  @Published var selectedEffect: CanvasEffect = .filterDelay
  @Published var strokeColor: Color = CanvasEffect.filterDelay.color

  var id: UUID

  @Published var selectedTool: InputTool = .loop


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

  // Effect stroke animation parameters
  static let effectInitialRadius: CGFloat = 18.0
  static let effectDecayPerTick: CGFloat = 0.8
  static let effectTimerInterval: TimeInterval = 1.0 / 30.0 // 30 FPS

  // Helper to compute total decay duration for a single point
  static var effectTotalDecayDuration: TimeInterval {
    // Time until radius decays to zero: initialRadius / decayPerTick * interval
    guard effectDecayPerTick > 0 else { return 0 }
    return TimeInterval(effectInitialRadius / effectDecayPerTick) * effectTimerInterval
  }

  // Effect parameter ranges (min/max) used for stroke-driven modulation
  // TODO - tune these
  static let delayTimeRange: ClosedRange<Double> = 0.05...2.0
  static let delayFeedbackRange: ClosedRange<Double> = 0.05...100.0
  static let reverbMixRange: ClosedRange<Double> = 0.1...0.8
  static let lowPassCutoffRange: ClosedRange<Double> = 500.0...12_000.0
  static let highPassCutoffRange: ClosedRange<Double> = 20.0...1000.0

  private var effectDecayTimer: AnyCancellable?

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
    self.strokeColor = selectedEffect.color
  }

  /// Computes a normalized strength from an effect point's radius relative to the initial radius.
  private func normalizedStrength(for point: EffectStroke.EffectPoint, lineWidth: CGFloat) -> Double {
    let maxRadius = max(Double(Self.effectInitialRadius), 1.0)
    let clamped = max(0.0, min(Double(point.radius), maxRadius))
    // Weight by line width (thicker strokes feel stronger); lineWidth is typically small, so normalize by a nominal value
    let widthFactor = max(0.2, min(Double(lineWidth) / 8.0, 2.0))
    return min(1.0, (clamped / maxRadius) * widthFactor)
  }

  /// Linearly interpolates within a range given a 0...1 normalized value
  private func lerp(in range: ClosedRange<Double>, val: Double) -> Float {
    return Float(range.lowerBound + (range.upperBound - range.lowerBound) * max(0.0, min(1.0, val)))
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

// Effect stroke drawing methods

extension CanvasViewModel {
  func beginEffectStroke(at point: CGPoint, color: Color = .blue, lineWidth: CGFloat = 8, opacity: Double = 0.5) {
    guard selectedTool == .effects else { return }
    let initial = EffectStroke.EffectPoint(position: point, radius: Self.effectInitialRadius)
    currentEffectStroke = EffectStroke(effect: selectedEffect, points: [initial], color: strokeColor, lineWidth: lineWidth, opacity: opacity)
    startEffectDecayTimerIfNeeded()
  }

  func updateCurrentEffectStroke(with point: CGPoint) {
    guard selectedTool == .effects else { return }
    guard var stroke = currentEffectStroke else { return }
    stroke.points.append(.init(position: point, radius: Self.effectInitialRadius))
    currentEffectStroke = stroke
  }

  func endEffectStroke(at point: CGPoint) {
    guard selectedTool == .effects else { return }
    guard var stroke = currentEffectStroke else { return }
    stroke.points.append(.init(position: point, radius: Self.effectInitialRadius))
    effectStrokes.append(stroke)
    currentEffectStroke = nil
    // Ensure timer is running to handle decay of newly added stroke
    startEffectDecayTimerIfNeeded()
  }

  func clearEffectStrokes() {
    effectStrokes.removeAll()
    currentEffectStroke = nil
    stopEffectDecayTimerIfNeeded()
  }

  func setSelectedEffect(_ effect: CanvasEffect) {
    selectedEffect = effect
    strokeColor = effect.color
  }

  private func startEffectDecayTimerIfNeeded() {
    guard effectDecayTimer == nil else { return }
    effectDecayTimer = Timer.publish(every: Self.effectTimerInterval, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in
        self?.handleEffectDecayTick()
      }
  }

  private func stopEffectDecayTimerIfNeeded() {
    effectDecayTimer?.cancel()
    effectDecayTimer = nil
  }

  private func handleEffectDecayTick() {
    let decay = Self.effectDecayPerTick

    // Decay points in active strokes
    var updatedStrokes: [EffectStroke] = []
    updatedStrokes.reserveCapacity(effectStrokes.count)

    for var stroke in effectStrokes {
      // decay each point's radius
      var remainingPoints: [EffectStroke.EffectPoint] = []
      remainingPoints.reserveCapacity(stroke.points.count)
      for var point in stroke.points {
        point.radius -= decay
        if point.radius > 0 {
          remainingPoints.append(point)
        }
      }
      stroke.points = remainingPoints
      if !stroke.points.isEmpty {
        updatedStrokes.append(stroke)
      }
    }

    // If there's a current stroke being drawn, also decay its points so it stays lively
    if var stroke = currentEffectStroke {
      var remainingPoints: [EffectStroke.EffectPoint] = []
      remainingPoints.reserveCapacity(stroke.points.count)
      for var point in stroke.points {
        point.radius -= decay
        if point.radius > 0 {
          remainingPoints.append(point)
        }
      }
      stroke.points = remainingPoints
      currentEffectStroke = stroke.points.isEmpty ? nil : stroke
    }

    effectStrokes = updatedStrokes

    // Apply stroke-driven modulation to EffectsRack
    if let rack = musicEngine.effectsRack {
      // Helper to map a point in canvas space to 0...1 normalized XY based on the visible rect
      func normalizeXY(from point: CGPoint) -> (x: Double, y: Double) {
        let rect = self.visibleEffectsRect
        let width = rect.width
        let height = rect.height

        // If we have a valid visible rect, focus normalization on its center region
        if width > 0 && height > 0 {
          // Middle 90% of width and middle 50% of height, centered within rect
          let focusedWidth = width * 0.90
          let focusedHeight = height * 0.50
          let focusedMinX = rect.minX + (width - focusedWidth) / 2.0
          let focusedMinY = rect.minY + (height - focusedHeight) / 2.0

          // Normalize within the focused sub-rect
          let nxRaw = (point.x - focusedMinX) / focusedWidth
          let nyRaw = (point.y - focusedMinY) / focusedHeight

          let nx = max(0.0, min(1.0, Double(nxRaw)))
          let ny = max(0.0, min(1.0, Double(nyRaw)))
          return (nx, ny)
        } else {
          // Fallback to whole-canvas normalization if no visible rect available
          let nx = max(0.0, min(1.0, Double(point.x / Self.canvasWidth)))
          let ny = max(0.0, min(1.0, Double(point.y / Self.canvasHeight)))
          return (nx, ny)
        }
      }

      // Emit XY mapping calls per active stroke using the stroke's end point
      func driveXY(for stroke: EffectStroke) {
        guard let last = stroke.points.last else { return }


        let amount = normalizedStrength(for: last, lineWidth: stroke.lineWidth)
        let (x, y) = normalizeXY(from: last.position)
        rack.mapXY(xVal: x, yVal: y, amount: amount, mode: stroke.effect.xyMode)
      }

      // Select most recent stroke per effect type so they don't compete
      var latestByEffect: [CanvasEffect: EffectStroke] = [:]
      // Keep the last occurrence in effectStrokes for each effect
      for stroke in effectStrokes {
        latestByEffect[stroke.effect] = stroke
      }
      // Current stroke (if any) should override for its effect type
      if let current = currentEffectStroke {
        latestByEffect[current.effect] = current
      }
      // Drive XY once per effect using the most recent stroke
      for (_, stroke) in latestByEffect {
        driveXY(for: stroke)
      }
    }

    // Stop timer if no strokes left anywhere
    if effectStrokes.isEmpty && currentEffectStroke == nil {
      stopEffectDecayTimerIfNeeded()
    }
  }
}

// Effects viewport
extension CanvasViewModel {
  func updateVisibleEffectsRect(canvasRect: CGRect, viewPortRect: CGRect) {
    let intersection = canvasRect.intersection(viewPortRect)
    let visible = intersection.isNull ? .zero : intersection
    self.visibleEffectsRect = visible
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

  func setInputTool(_ inputTool: InputTool) {
    self.selectedTool = inputTool
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

  func reloadSong() {
    if let canvasStore = canvasStore, let canvasModel = canvasStore.loadCanvas(name: canvasModel.name) {
      resetCanvasModel(newCanvasModel: canvasModel)
    }
  }

  func loadSong(name: String) {
    if let canvasStore = canvasStore, let canvasModel = canvasStore.loadCanvas(name: name) {
      resetCanvasModel(newCanvasModel: canvasModel)
    }
  }

  func newSong() {
    if let canvasStore = canvasStore {
      let canvasModel = CanvasModel(sampleSetStore: canvasStore.sampleSetStore)
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

