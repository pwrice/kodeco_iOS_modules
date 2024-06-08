//
//  CanvasModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI


class CanvasModel: ObservableObject {
  @Published var blocksGroups: [BlockGroup] = []
  @Published var library = Library()


  init() {
  }

  func addBlockGroup(initialBlock: Block) {
    blocksGroups.append(BlockGroup(id: BlockGroup.getNextBlockGroupId(), block: initialBlock))
  }
  func removeBlockGroup(blockGroup: BlockGroup) {
    blocksGroups.removeAll { $0.id == blockGroup.id }
  }
}
