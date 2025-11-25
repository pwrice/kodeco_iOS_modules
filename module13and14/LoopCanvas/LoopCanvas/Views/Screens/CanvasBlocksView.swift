import SwiftUI

struct CanvasBlocksView: View {
  @ObservedObject var viewModel: CanvasViewModel
  @Binding var showingBlockDetailsView: Bool
  @Binding var showingBlockGroupDetailsView: Bool

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?
  @GestureState private var groupDragStartLocation: CGPoint?

  func blockDragGesture(block: Block) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($dragStartLocation) { _, startLocation, _ in
        guard viewModel.selectedTool == .loop else { return }

        // Called before onChanged
        startLocation = startLocation ?? block.location
      }
      .onChanged { value in
        guard viewModel.selectedTool == .loop else { return }

        var newLocation = dragStartLocation ?? block.location
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockDragLocation(block: block, location: newLocation)
      }
      .onEnded { _ in
        guard viewModel.selectedTool == .loop else { return }

        _ = viewModel.dropBlockOnCanvas(block: block)
      }
  }

  func blockGroupDragGesture(blockGroup: BlockGroup) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($groupDragStartLocation) { _, startLocation, _ in
        guard viewModel.selectedTool == .loop else { return }

        // Called before onChanged
        startLocation = startLocation ?? (blockGroup.leftMostBlock?.location ?? .zero)
      }
      .onChanged { value in
        guard viewModel.selectedTool == .loop else { return }

        var newLocation = groupDragStartLocation ?? (blockGroup.leftMostBlock?.location ?? .zero)
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockGroupDragLocation(blockGroup: blockGroup, location: newLocation)
      }
      .onEnded { _ in
        guard viewModel.selectedTool == .loop else { return }

        _ = viewModel.dropBlockGroupOnCanvas(blockGroup: blockGroup)
      }
  }

  var body: some View {
    ZStack { // This is just the blocks
      Spacer()
      ForEach(viewModel.allBlocks) { blockModel in
        PositionedBlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
          .simultaneousGesture(
            TapGesture()
              .onEnded { _ in
                guard viewModel.selectedTool == .loop else { return }

                viewModel.selectBlock(block: blockModel)
                showingBlockDetailsView = true
              }
          )
      }

      ForEach(viewModel.allBlockGroups, id: \.id) { group in
        if group.allBlocks.count >= 2, let left = group.leftMostBlock {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .overlay(
              Image(systemName: "slider.vertical.3")
                .foregroundColor(.gray)
            )
            .frame(width: 20, height: max(40, CGFloat(left.numBars) * (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing)))
            .position(CGPoint(
              x: left.location.x - (CanvasViewModel.blockSize / 2) - CanvasViewModel.blockSpacing - 12,
              y: left.location.y
            ))
            .gesture(blockGroupDragGesture(blockGroup: group))
            .simultaneousGesture(
              TapGesture()
                .onEnded { _ in
                  guard viewModel.selectedTool == .loop else { return }

                  viewModel.selectBlockGroup(group: group)
                  showingBlockGroupDetailsView = true
                }
            )
        }
      }
    }
  }
}
