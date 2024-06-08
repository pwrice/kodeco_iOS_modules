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

  var blockGroupGridPosX: Int?
  var blockGroupGridPosY: Int?
  weak var blockGroup: BlockGroup?

  var loopURL: URL?

  static var blockIdCounter: Int = 0
  static func getNextBlockId() -> Int {
    let blockId = blockIdCounter
    blockIdCounter += 1
    return blockId
  }

  init(id: Int, location: CGPoint, color: Color, visible: Bool = false, loopFile: URL? = nil) {
    self.id = id
    self.location = location
    self.color = color
    self.visible = visible
    self.loopURL = loopFile
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
