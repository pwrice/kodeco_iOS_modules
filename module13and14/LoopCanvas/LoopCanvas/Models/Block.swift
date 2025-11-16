//
//  BlockModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation
import SwiftUI
import os

struct BlockDTO: Codable {
  let id: UUID
  let location: CGPoint
  let color: Block.Colors
  let relativePath: String?
  let icon: String
  let blockGroupGridPosX: Int?
  let blockGroupGridPosY: Int?
  let startOffset: Int
  let volume: Double
  let numBars: Int
  let isMuted: Bool
}

class Block: ObservableObject, Identifiable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: Block.self)
  )

  // Persistent props
  @Published var id: UUID
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

  static func getNextBlockId() -> UUID {
    return UUID()
  }

  init(
    id: UUID,
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

  convenience init(dto: BlockDTO) {
    self.init(
      id: dto.id,
      location: dto.location,
      color: dto.color.color,
      icon: dto.icon,
      visible: true,
      loopURL: dto.relativePath != nil ? URL(fileURLWithPath: dto.relativePath!, relativeTo: Bundle.main.bundleURL) : nil,
      relativePath: dto.relativePath,
      isLibraryBlock: false
    )
    self.blockGroupGridPosX = dto.blockGroupGridPosX
    self.blockGroupGridPosY = dto.blockGroupGridPosY
    self.startOffset = dto.startOffset
    self.volume = dto.volume
    self.numBars = dto.numBars
    self.isMuted = dto.isMuted
  }

  func toDTO() -> BlockDTO {
    BlockDTO(
      id: self.id,
      location: self.location,
      color: Colors.from(color: self.normalColor),
      relativePath: self.relativePath,
      icon: self.icon,
      blockGroupGridPosX: self.blockGroupGridPosX,
      blockGroupGridPosY: self.blockGroupGridPosY,
      startOffset: self.startOffset,
      volume: self.volume,
      numBars: self.numBars,
      isMuted: self.isMuted
    )
  }

  func instantiateCopyWith(location: CGPoint, isLibraryBlock: Bool = false) -> Block {
    let copy = Block(
      id: Block.getNextBlockId(),
      location: location,
      color: self.normalColor,
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
    copy.color = self.normalColor
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
