//
//  BlockView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct BlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .foregroundColor(model.color)
        .opacity(model.visible ? 1 : 0)
        .overlay {
          Image(systemName: model.icon)
            .foregroundColor(.white)
        }
    }
    .frame(
      width: CanvasViewModel.blockSize,
      height: CanvasViewModel.blockSize)
    .position(model.location)
  }
}
