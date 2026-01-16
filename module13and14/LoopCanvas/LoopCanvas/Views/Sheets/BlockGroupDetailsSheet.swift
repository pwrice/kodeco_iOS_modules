import SwiftUI

private enum Style {
  // Layout
  static let rowSpacing: CGFloat = 16
  static let contentPadding: CGFloat = 16
  static let smallSpacing: CGFloat = 8

  // Card
  static let cardPadding: CGFloat = 16
  static let cardCornerRadius: CGFloat = 22
  static let cardShadowColor = Color(.sRGBLinear, white: 0, opacity: 0.12)
  static let cardShadowRadius: CGFloat = 10
  static let cardShadowX: CGFloat = 0
  static let cardShadowY: CGFloat = 6

  // Small shadow (for subtle elements)
  static let smallShadowColor = Color(.sRGBLinear, white: 0, opacity: 0.12)
  static let smallShadowRadius: CGFloat = 6
  static let smallShadowX: CGFloat = 0
  static let smallShadowY: CGFloat = 3

  // Colors
  static let cardFill = Color(.systemBackground)
  static let secondaryBackground = Color(.secondarySystemBackground)
  static let accent = Color.blue

  // Bottom action buttons
  static let pillHorizontalPadding: CGFloat = 18
  static let pillVerticalPadding: CGFloat = 12
}

struct BlockGroupDetailsSheet: View {
  @ObservedObject var canvasViewModel: CanvasViewModel
  let group: BlockGroup
  @Binding var isPresented: Bool

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: Style.rowSpacing) {
          BlockGroupDetailsCardView(
            group: group,
            canvasViewModel: canvasViewModel
          )

          Divider()
            .padding(.vertical, Style.smallSpacing)

          // Bottom actions
          HStack(spacing: Style.rowSpacing) {
            Button {
              _ = canvasViewModel.duplicate(blockGroup: group)
              isPresented = false
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "square.on.square")
                Text("Duplicate Group")
              }
              .foregroundColor(Style.accent)
              .padding(.horizontal, Style.pillHorizontalPadding)
              .padding(.vertical, Style.pillVerticalPadding)
              .background(
                Capsule()
                  .fill(Style.cardFill)
                  .shadow(color: Style.cardShadowColor, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
              )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
              canvasViewModel.delete(blockGroup: group)
              isPresented = false
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Delete Group")
              }
              .padding(.horizontal, Style.pillHorizontalPadding)
              .padding(.vertical, Style.pillVerticalPadding)
              .background(
                Capsule()
                  .fill(Style.cardFill)
                  .shadow(color: Style.cardShadowColor, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding(Style.contentPadding)
      }
      .navigationTitle("Group Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { isPresented = false }
        }
      }
    }
  }
}

private struct BlockGroupDetailsCardView: View {
  @ObservedObject var group: BlockGroup
  @ObservedObject var canvasViewModel: CanvasViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: Style.rowSpacing) {
      VStack(alignment: .leading, spacing: Style.smallSpacing) {
        HStack {
          Text("Volume")
            .font(.headline)
          Spacer()
          Text("\(Int(round(group.volume * 100.0)))%")
            .foregroundColor(.secondary)
        }

        Slider(
          value: Binding(
            get: { group.volume },
            set: { newValue in
              canvasViewModel.update(volume: newValue, for: group)
            }
          ),
          in: 0...1
        )
        // Mute pill
        Button {
          canvasViewModel.toggleMute(blockGroup: group)
        } label: {
          HStack(spacing: 8) {
            Image(systemName: "speaker.slash")
            Text(group.allBlocks.contains { !$0.isMuted } ? "Mute Group" : "Unmute Group")
          }
          .font(.headline)
          .foregroundColor(Style.accent)
          .padding(.horizontal, Style.pillHorizontalPadding)
          .padding(.vertical, Style.pillVerticalPadding)
          .background(
            Capsule()
              .fill(Style.cardFill)
              .shadow(color: Style.smallShadowColor, radius: Style.smallShadowRadius, x: Style.smallShadowX, y: Style.smallShadowY)
          )
        }
        .buttonStyle(.plain)
        .padding(.top, Style.smallSpacing / 2)
      }
    }
    .padding(Style.cardPadding)
    .background(
      RoundedRectangle(cornerRadius: Style.cardCornerRadius, style: .continuous)
        .fill(Style.cardFill)
        .shadow(color: Style.cardShadowColor, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
    )
  }
}

#Preview("Block Group Details") {
  // Local preview scaffolding
  @Previewable @State var isPresented = true

  // Reuse helpers analogous to BlockDetailsSheet
  let canvasVM = CanvasViewModel.previewMock()

  // Create a small group with two blocks for preview
  let blockA = Block(
    id: Block.getNextBlockId(),
    location: CGPoint(x: 200, y: 200),
    color: .blue,
    icon: "circle",
    loopURL: URL(fileURLWithPath: "Samples/Funk/Drums/Funky.wav", relativeTo: Bundle.main.bundleURL),
    relativePath: "Samples/Funk/Drums/Funky.wav",
    isLibraryBlock: false
  )
  blockA.numBars = 1
  blockA.volume = 0.6

  let blockB = Block(
    id: Block.getNextBlockId(),
    location: CGPoint(x: 200 + CanvasViewModel.gridSpacing(), y: 200),
    color: .green,
    icon: "square",
    loopURL: URL(fileURLWithPath: "Samples/Dub/Horns/horns-5.wav", relativeTo: Bundle.main.bundleURL),
    relativePath: "Samples/Dub/Horns/horns-5.wav",
    isLibraryBlock: false
  )
  blockB.numBars = 2
  blockB.volume = 0.8

  // Add both blocks to the canvas by dropping them (to ensure groups are formed) 
  let droppedA = canvasVM.dropBlockOnCanvas(block: blockA)
  _ = canvasVM.dropBlockOnCanvas(block: blockB)

  // Ensure we have the group that contains droppedA
  let group = droppedA.blockGroup ?? {
    // Fallback: create a group from A if grouping didn't happen automatically
    canvasVM.canvasModel.addBlockGroup(initialBlock: droppedA)
    return droppedA.blockGroup!
  }()

  return BlockGroupDetailsSheet(
    canvasViewModel: canvasVM,
    group: group,
    isPresented: $isPresented
  )
}
