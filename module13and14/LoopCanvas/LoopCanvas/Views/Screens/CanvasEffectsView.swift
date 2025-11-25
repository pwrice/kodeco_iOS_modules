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
        ZStack {
          // Draw variable-width segments between consecutive points
          ForEach(Array(stroke.points.enumerated()), id: \.offset) { idx, point in
            if idx > 0 {
              let prev = stroke.points[idx - 1]
              // Use the smaller radius between the two points for a smooth join
              let width = max(0.5, min(prev.radius, point.radius) * 2)
              Path { path in
                path.move(to: prev.position)
                path.addLine(to: point.position)
              }
              .stroke(
                stroke.colorValue.opacity(stroke.opacity),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
              )
            }
          }

          // Also render single-point dots so isolated points appear
          if stroke.points.count == 1, let only = stroke.points.first {
            Circle()
              .fill(stroke.colorValue.opacity(stroke.opacity))
              .frame(width: max(1, only.radius * 2), height: max(1, only.radius * 2))
              .position(only.position)
          }
        }
      }

      // Render current in-progress stroke if any
      if let current = viewModel.currentEffectStroke {
        ZStack {
          ForEach(Array(current.points.enumerated()), id: \.offset) { idx, point in
            if idx > 0 {
              let prev = current.points[idx - 1]
              let width = max(0.5, min(prev.radius, point.radius) * 2)
              Path { path in
                path.move(to: prev.position)
                path.addLine(to: point.position)
              }
              .stroke(
                current.colorValue.opacity(current.opacity),
                style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
              )
            }
          }
          if current.points.count == 1, let only = current.points.first {
            Circle()
              .fill(current.colorValue.opacity(current.opacity))
              .frame(width: max(1, only.radius * 2), height: max(1, only.radius * 2))
              .position(only.position)
          }
        }
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
