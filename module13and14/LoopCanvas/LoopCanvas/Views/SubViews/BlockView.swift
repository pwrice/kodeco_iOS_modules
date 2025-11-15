//
//  BlockView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

private enum Style {
  // Corner radii
  static let blockCornerRadius: CGFloat = 10

  // Selection stroke
  static let selectionStrokeColor: Color = .cyan
  static let selectionStrokeLineWidth: CGFloat = 2

  // Icon color
  static let iconColor: Color = .white
}

struct PositionedBlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    ZStack {
      let backgroundWidth = (CGFloat(model.numBars) * CanvasViewModel.blockSize) +
        ((CGFloat(model.numBars) - 1.0) * CanvasViewModel.blockSpacing)
      // Because the subviews are positioned by their center, the wider they are the more
      // we need to move them to the left
      let backgroundOffset = (backgroundWidth / 2) - (CanvasViewModel.blockSize / 2)

      RoundedRectangle(cornerRadius: Style.blockCornerRadius)
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
          RoundedRectangle(cornerRadius: Style.blockCornerRadius)
            .fill(model.color == model.highlightColor
                  && index == model.currentRelativeBar ? model.color : .clear)
            .opacity(model.visible ? 1 : 0)
            .overlay {
              if index == 0 {
                Image(systemName: model.icon)
                  .foregroundColor(Style.iconColor)
              }
            }
        }
        .frame(
          width: CanvasViewModel.blockSize,
          height: CanvasViewModel.blockSize)
        .position(location)
      }

      RoundedRectangle(cornerRadius: Style.blockCornerRadius)
        .fill(.clear)
        .stroke(Style.selectionStrokeColor, lineWidth: Style.selectionStrokeLineWidth)
        .opacity(model.isSelected ? 1 : 0)
        .frame(
          width: backgroundWidth,
          height: CanvasViewModel.blockSize)
        .position(CGPoint(x: model.location.x + backgroundOffset, y: model.location.y))
    }
  }
}


struct PreviewBlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: Style.blockCornerRadius)
        .foregroundColor(model.normalColor)
        .overlay {
          Image(systemName: model.icon)
            .foregroundColor(Style.iconColor)
        }
    }
  }
}

#Preview("Block Views") {
  // Sample block for previews
  let block = Block(
    id: Block.getNextBlockId(),
    location: CGPoint(x: 150, y: 150),
    color: .blue,
    icon: "music.note",
    loopURL: URL(fileURLWithPath: "Samples/Fink/Drums/Funky_105a_timefix.wav", relativeTo: Bundle.main.bundleURL),
    relativePath: "Samples/Fink/Drums/Funky_105a_timefix.wav",
    isLibraryBlock: false
  )
  block.numBars = 2
  block.visible = true
  block.isSelected = true

  return ZStack {
    Color(.systemBackground)
      .ignoresSafeArea()

    VStack(spacing: 24) {
      PositionedBlockView(model: block)
        .frame(width: 320, height: 300)

      PreviewBlockView(model: block)
        .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
    }
  }
}
