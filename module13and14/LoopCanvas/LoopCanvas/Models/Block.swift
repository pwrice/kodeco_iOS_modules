//
//  BlockModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation
import SwiftUI

class Block: ObservableObject, Identifiable {
  @Published var id: Int
  @Published var location: CGPoint
  @Published var color: Color
  @Published var visible = true
  @Published var dragging = false

  let normalColor: Color
  let highlightColor: Color = .yellow
  let isLibraryBlock: Bool

  weak var blockGroup: BlockGroup?
  var isPlaying = false
  var blockGroupGridPosX: Int?
  var blockGroupGridPosY: Int?
  var loopPlayer: LoopPlayer?
  var loopURL: URL?

  static var blockIdCounter: Int = 0
  static func getNextBlockId() -> Int {
    let blockId = blockIdCounter
    blockIdCounter += 1
    return blockId
  }

  init(id: Int, location: CGPoint, color: Color, visible: Bool = false, loopURL: URL? = nil, isLibraryBlock: Bool = false) {
    self.id = id
    self.location = location
    self.color = color
    self.normalColor = color
    self.visible = visible
    self.loopURL = loopURL
    self.isLibraryBlock = isLibraryBlock
  }

  func tick(step16: Int) {
    if step16 % 4 == 0 && isPlaying {
      color = highlightColor
    } else if color != normalColor {
      color = normalColor
    }
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
