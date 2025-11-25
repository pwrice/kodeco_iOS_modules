import SwiftUI

struct CanvasEffectsView: View {
  @ObservedObject var viewModel: CanvasViewModel
  @GestureState private var dragLocation: CGPoint?

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.clear)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Render existing strokes
      ForEach(viewModel.effectStrokes) { stroke in
        Path { path in
          guard let first = stroke.points.first else { return }
          path.move(to: first)
          for point in stroke.points.dropFirst() {
            path.addLine(to: point)
          }
        }
        .stroke(
          stroke.colorValue.opacity(stroke.opacity),
          style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
      }

      // Render current in-progress stroke if any
      if let current = viewModel.currentEffectStroke {
        Path { path in
          guard let first = current.points.first else { return }
          path.move(to: first)
          for point in current.points.dropFirst() {
            path.addLine(to: point)
          }
        }
        .stroke(
          current.colorValue.opacity(current.opacity),
          style: StrokeStyle(lineWidth: current.lineWidth, lineCap: .round, lineJoin: .round))
      }
    }
    .contentShape(Rectangle())
    .gesture(drawingGesture)
    .allowsHitTesting(viewModel.selectedTool == .effects)
    .accessibilityHidden(viewModel.selectedTool != .effects)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var drawingGesture: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .updating($dragLocation) { value, state, _ in
        guard viewModel.selectedTool == .effects else { return }
        state = value.location
        viewModel.updateCurrentEffectStroke(with: value.location)
      }
      .onChanged { value in
        guard viewModel.selectedTool == .effects else { return }
        if viewModel.currentEffectStroke == nil {
          viewModel.beginEffectStroke(at: value.location)
        } else {
          viewModel.updateCurrentEffectStroke(with: value.location)
        }
      }
      .onEnded { value in
        guard viewModel.selectedTool == .effects else { return }
        viewModel.endEffectStroke(at: value.location)
      }
  }
}

// MARK: - Preview
#Preview("Canvas Effects") {
  let viewModel = CanvasViewModel.previewMock()
  viewModel.selectedTool = .effects
  return ZStack {
    Color.gray.opacity(0.1)
    CanvasEffectsView(viewModel: viewModel)
  }
  .frame(width: 300, height: 300)
}
