//
//  BlockView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct PositionedBlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    ZStack {
      var backgroundWidth = (CGFloat(model.numBars) * CanvasViewModel.blockSize) +
        ((CGFloat(model.numBars) - 1.0) * CanvasViewModel.blockSpacing)
      var backgroundOffset = (backgroundWidth / 2) - (CanvasViewModel.blockSize / 2)

      RoundedRectangle(cornerRadius: 10) // TODO - add this to constants somewhere
        .foregroundColor(model.normalColor)
        .opacity(model.visible ? 1 : 0)
        .frame(
          width: backgroundWidth,
          height: CanvasViewModel.blockSize)
        .position(CGPoint(x: model.location.x + backgroundOffset, y: model.location.y))
      ForEach(0..<model.numBars, id: \.self) { index in
        let locX = model.location.x + CGFloat(index) * (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing)
        let location = CGPoint(x: locX, y: model.location.y)
        ZStack {
          RoundedRectangle(cornerRadius: 10) // TODO - add this to constants somewhere
            .fill(model.color == model.highlightColor
                  && index == model.currentRelativeBar ? model.color : .clear)
            .opacity(model.visible ? 1 : 0)
            .overlay {
              if index == 0 {
                Image(systemName: model.icon)
                  .foregroundColor(.white)
              }
            }
          RoundedRectangle(cornerRadius: 10) // TODO - make this a constant
            .fill(.clear)
            .stroke(.cyan, lineWidth: 2) // TODO - put these colors into Assets
            .opacity(model.isSelected ? 1 : 0)
        }
        .frame(
          width: CanvasViewModel.blockSize,
          height: CanvasViewModel.blockSize)
        .position(location)
      }
    }
  }
}

// struct BlockView: View {
//  @ObservedObject var model: Block
//
//  var body: some View {
//    ZStack {
//      RoundedRectangle(cornerRadius: 10) // TODO - add this to constants somewhere
//        .foregroundColor(model.color)
//        .opacity(model.visible ? 1 : 0)
//        .overlay {
//          Image(systemName: model.icon)
//            .foregroundColor(.white)
//        }
//      RoundedRectangle(cornerRadius: 10) // TODO - make this a constant
//        .fill(.clear)
//        .stroke(.cyan, lineWidth: 2) // TODO - put these colors into Assets
//        .opacity(model.isSelected ? 1 : 0)
//    }
//  }
// }

struct PreviewBlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 10)
        .foregroundColor(model.normalColor)
        .overlay {
          Image(systemName: model.icon)
            .foregroundColor(.white)
        }
    }
  }
}
