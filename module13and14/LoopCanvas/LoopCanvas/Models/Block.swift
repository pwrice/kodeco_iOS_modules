//
//  BlockModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation
import SwiftUI
import os

class Block: ObservableObject, Identifiable, Codable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: Block.self)
  )

  // Persistent props
  @Published var id: Int
  @Published var location: CGPoint
  @Published var color: Color

  var blockGroupGridPosX: Int?
  var blockGroupGridPosY: Int?
  var startBlockGroupGridPosX: Int? {
    blockGroupGridPosX
  }
  var endBlockGroupGridPosX: Int? {
    if let blockGroupGridPosX = blockGroupGridPosX {
      return blockGroupGridPosX + (numBars - 1)
    }
    return nil
  }
  func blockGroupXSpanContains(posX: Int) -> Bool {
    if let startBlockGroupGridPosX = startBlockGroupGridPosX,
      let endBlockGroupGridPosX = endBlockGroupGridPosX {
      return posX >= startBlockGroupGridPosX && posX <= endBlockGroupGridPosX
    }
    return false
  }

  var loopURL: URL?
  let icon: String
  var relativePath: String?

  // Transient state props
  @Published var visible = true
  @Published var dragging = false

  let normalColor: Color
  let highlightColor: Color = .yellow
  let isLibraryBlock: Bool

  weak var blockGroup: BlockGroup?
  var isPlaying = false
  var loopPlayer: LoopPlayer?
  var isSelected = false
  var isMuted = false

  var numBars = 1
  var startOffset: Int = 0 // in bars
  var maxNumBars: Int {
    if let loopPlayer = loopPlayer {
      return loopPlayer.maxNumBars
    }
    return defaultMaxNumBars
  }
  var defaultMaxNumBars = 1

  var currentRelativeBar = 0
  @Published var loopPlayPosition: Double = 0.0 // 0.0 ... 1.0 normalized within current loop
  @Published var samplePlayPosition: Double = 0.0 // 0.0 ... 1.0 full sample length

  var timeUntilNextBar: Double {
    blockGroup?.musicEngine?.timeUntilNextBar() ?? defaultTimeUntilNextBar
  }
  var defaultTimeUntilNextBar = 1.0
  @Published var triggerBlockLoadingAnimation = false

  // 0.0 ... 1.0 full sample length
  var sampleStartTime: Double {
    if let loopPlayer {
      return loopPlayer.sampleStartTime
    }
    return defaultSampleStartTime
  }
  var defaultSampleStartTime = 1.0

  // 0.0 ... 1.0 full sample length
  var sampleEndTime: Double {
    if let loopPlayer {
      return loopPlayer.sampleEndTime
    }
    return defaultSampleEndTime
  }
  var defaultSampleEndTime = 1.0


  var name: String {
    if let loopURL = loopURL {
      return loopURL.lastPathComponent
    }
    return ""
  }

  var volume: Double = 0.75        // 0...1

  static var blockIdCounter: Int = 0
  static func getNextBlockId() -> Int {
    let blockId = blockIdCounter
    blockIdCounter += 1
    return blockId
  }

  init(
    id: Int,
    location: CGPoint,
    color: Color,
    icon: String,
    visible: Bool = false,
    loopURL: URL? = nil,
    relativePath: String? = nil,
    isLibraryBlock: Bool = false
  ) {
    self.id = id
    self.location = location
    self.color = color
    self.icon = icon
    self.relativePath = relativePath
    self.normalColor = color
    self.visible = visible
    self.loopURL = loopURL
    self.isLibraryBlock = isLibraryBlock
  }

  func instantiateCopyWith(location: CGPoint, isLibraryBlock: Bool) -> Block {
    let copy = Block(
      id: Block.getNextBlockId(),
      location: location,
      color: self.color,
      icon: self.icon,
      visible: self.visible,
      loopURL: self.loopURL,
      relativePath: self.relativePath,
      isLibraryBlock: isLibraryBlock
    )
    copy.numBars = self.numBars
    copy.isMuted = self.isMuted
    copy.startOffset = self.startOffset
    copy.volume = self.volume
    return copy
  }

  func tick(step16: Int) {
    if step16 % 4 == 0 && isPlaying {
      color = highlightColor
    } else if color != normalColor {
      color = normalColor
    }

    if let loopPlayer = loopPlayer {
      loopPlayPosition = loopPlayer.loopPlayPosition
      samplePlayPosition = loopPlayer.samplePlayPosition
    } else {
      loopPlayPosition = 0.0
      samplePlayPosition = 0.0
    }
  }

  // Codable implementation

  enum Colors: String, Codable, CaseIterable {
    case pink
    case purple
    case indigo
    case orange
    case blue
    case cyan
    case green

    var color: Color {
      switch self {
      case .pink: return Color.pink
      case .purple: return Color.purple
      case .indigo: return Color.indigo
      case .orange: return Color.orange
      case .blue: return Color.blue
      case .cyan: return Color.cyan
      case .green: return Color.green
      }
    }

    static func from(color: Color) -> Self {
      switch color {
      case .pink: return .pink
      case .purple: return .purple
      case .indigo: return .indigo
      case .orange: return .orange
      case .blue: return .blue
      case .cyan: return .cyan
      case .green: return .green
      default: return .green
      }
    }
  }

  enum CodingKeys: String, CodingKey {
    case id,
      location,
      color,
      relativePath,
      icon,
      blockGroupGridPosX,
      blockGroupGridPosY,
      startOffset,
      volume,
      numBars,
      isMuted
  }

  required init(from decoder: Decoder) throws {
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(Int.self, forKey: .id)
      location = try container.decode(CGPoint.self, forKey: .location)
      let colorEnum = try container.decode(Colors.self, forKey: .color)
      icon = try container.decode(String.self, forKey: .icon)
      relativePath = try container.decode(String.self, forKey: .relativePath)
      blockGroupGridPosX = try container.decodeIfPresent(Int.self, forKey: .blockGroupGridPosX)
      blockGroupGridPosY = try container.decodeIfPresent(Int.self, forKey: .blockGroupGridPosY)
      startOffset = try container.decodeIfPresent(Int.self, forKey: .startOffset) ?? 0
      volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.75
      numBars = try container.decodeIfPresent(Int.self, forKey: .numBars) ?? 1
      isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false

      color = colorEnum.color
      normalColor = colorEnum.color
      visible = true
      isLibraryBlock = false
      if let relativePath = relativePath {
        loopURL = URL(fileURLWithPath: relativePath, relativeTo: Bundle.main.bundleURL)
      }
    } catch {
      Self.logger.error("Block decode error: \(error)")
      throw error
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(location, forKey: .location)
    let colorEnum = Colors.from(color: normalColor)
    try container.encode(colorEnum, forKey: .color)
    try container.encode(icon, forKey: .icon)
    try container.encode(relativePath, forKey: .relativePath)
    try container.encode(blockGroupGridPosX, forKey: .blockGroupGridPosX)
    try container.encode(blockGroupGridPosY, forKey: .blockGroupGridPosY)
    try container.encode(startOffset, forKey: .startOffset)
    try container.encode(volume, forKey: .volume)
    try container.encode(numBars, forKey: .numBars)
    try container.encode(isMuted, forKey: .isMuted)
  }
}

extension Block: Equatable {
  static func == (lhs: Block, rhs: Block) -> Bool {
    lhs.id == rhs.id &&
    lhs.location == rhs.location &&
    lhs.color == rhs.color &&
    lhs.blockGroupGridPosX == rhs.blockGroupGridPosX &&
    lhs.blockGroupGridPosY == rhs.blockGroupGridPosY
  }
}
