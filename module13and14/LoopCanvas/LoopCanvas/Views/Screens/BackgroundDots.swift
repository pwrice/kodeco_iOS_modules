import SwiftUI


struct BackgroundDots: View {
  let addBlockTapGridPosition: CGPoint?

  func highlightBlock(x: Int, y: Int) -> Bool {
    return (addBlockTapGridPosition?.x == CGFloat(x) &&
            addBlockTapGridPosition?.y == CGFloat(y))
  }

  var body: some View {
    ZStack { // Background dots
      let dotSpacing = CanvasViewModel.gridSpacing()
      let (numCols, numRows) = CanvasViewModel.gridDimensions()
      ForEach(0..<numCols, id: \.self) { hInd in
        ForEach(0..<numRows, id: \.self) { vInd in
          ZStack {
            RoundedRectangle(cornerRadius: 10) // TODO - make this a constant
              .fill(.clear)
              .stroke(.gray, lineWidth: 2) // TODO - put these colors into Assets
              .opacity(highlightBlock(x: hInd, y: vInd) ? 1 : 0)
              .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
              .position(CGPoint(
                x: (CGFloat(hInd) * dotSpacing) + (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2,
                y: (CGFloat(vInd) * dotSpacing) + (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2
              ))
            Rectangle()
              .foregroundColor(.gray)
              .frame(width: 2, height: 2)
              .position(CGPoint(
                x: CGFloat(hInd) * dotSpacing,
                y: CGFloat(vInd) * dotSpacing))
          }
        }
      }
    }
  }
}
