//
//  BlockDetailsSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/9/25.
//

import SwiftUI
import Waveform

private enum Style {
  // Sizes
  static let waveformHeight: CGFloat = 100
  static let blockPreviewScale: CGFloat = 0.5
  static let circularButtonSize: CGFloat = 30

  // Paddings
  static let cardPadding: CGFloat = 16
  static let rowSpacing: CGFloat = 16
  static let smallSpacing: CGFloat = 8
  static let contentPadding: CGFloat = 16
  static let pillHorizontalPadding: CGFloat = 16
  static let pillVerticalPadding: CGFloat = 10
  static let bottomButtonHorizontalPadding: CGFloat = 18
  static let bottomButtonVerticalPadding: CGFloat = 12

  // Corner radii
  static let cardCornerRadius: CGFloat = 22
  static let waveformCornerRadius: CGFloat = 18

  // Shadows
  static let smallShadowColor = Color(.sRGBLinear, white: 0, opacity: 0.12)
  static let smallShadowRadius: CGFloat = 6
  static let smallShadowX: CGFloat = 0
  static let smallShadowY: CGFloat = 3

  static let cardShadowColor = Color(.sRGBLinear, white: 0, opacity: 0.12)
  static let cardShadowRadius: CGFloat = 10
  static let cardShadowX: CGFloat = 0
  static let cardShadowY: CGFloat = 6

  // Colors
  static let cardFill = Color(.systemBackground)
  static let secondaryBackground = Color(.secondarySystemBackground)
  static let accent = Color.blue
}

struct BlockDetailsSheet: View {
  @Binding var showingBlockDetailsView: Bool
  @ObservedObject var canvasViewModel: CanvasViewModel
  @ObservedObject var viewModel: BlockDetailsViewModel
  let showLiveWaveform: Bool

  // MARK: - Helpers

  private func clampBars(_ value: Int) -> Int {
    max(1, min(viewModel.block.maxNumBars, value))
  }

  private func clampStartOffset(_ value: Int) -> Int {
    let maxBeats = max(0, (viewModel.block.maxNumBars * 4) - 1)
    return max(0, min(maxBeats, value))
  }

  private func volumePercent(_ volume: Double) -> Int {
    Int(round(volume * 100.0))
  }

  // MARK: - View

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: Style.rowSpacing) {
          // Card
          VStack(alignment: .leading, spacing: Style.rowSpacing) {
            // Waveform header
            ZStack {
              RoundedRectangle(cornerRadius: Style.waveformCornerRadius, style: .continuous)
                .fill(Style.secondaryBackground)
                .overlay(
                  Group {
                    if showLiveWaveform {
                      Waveform(samples: viewModel.samples)
                        .foregroundColor(.green)
                        .padding(Style.contentPadding - 4)
                    } else {
                      Color.clear
                    }
                  }
                )
                .clipShape(RoundedRectangle(cornerRadius: Style.waveformCornerRadius, style: .continuous))
            }
            .frame(height: Style.waveformHeight)

            // Number of Bars row
            rowWithSteppers(
              title: "Number of Bars",
              valueText: "\(viewModel.block.numBars)",
              onDecrement: {
                let newVal = clampBars(viewModel.block.numBars - 1)
                if newVal != viewModel.block.numBars {
                  canvasViewModel.update(numBars: newVal, for: viewModel.block)
                }
              },
              onIncrement: {
                let newVal = clampBars(viewModel.block.numBars + 1)
                if newVal != viewModel.block.numBars {
                  canvasViewModel.update(numBars: newVal, for: viewModel.block)
                }
              }
            )

            Divider()

            // Start Offset row
            rowWithSteppers(
              title: "Start Offset",
              valueText: "\(viewModel.block.startOffset)",
              onDecrement: {
                let newVal = clampStartOffset(viewModel.block.startOffset - 1)
                if newVal != viewModel.block.startOffset {
                  canvasViewModel.update(startOffset: newVal, for: viewModel.block)
                }
              },
              onIncrement: {
                let newVal = clampStartOffset(viewModel.block.startOffset + 1)
                if newVal != viewModel.block.startOffset {
                  canvasViewModel.update(startOffset: newVal, for: viewModel.block)
                }
              }
            )

            Divider()

            // Volume row
            VStack(alignment: .leading, spacing: Style.smallSpacing) {
              HStack {
                Text("Volume")
                  .font(.headline)
                Spacer()
                Text("\(volumePercent(viewModel.block.volume))%")
                  .foregroundColor(.secondary)
              }

              Slider(
                value: Binding(
                  get: { viewModel.block.volume },
                  set: { newValue in
                    let clamped = max(0.0, min(1.0, newValue))
                    canvasViewModel.update(volume: clamped, for: viewModel.block)
                  }),
                in: 0...1
              )
            }

            // Mute pill
            Button {
              canvasViewModel.toggleMute(block: viewModel.block)
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "speaker.slash")
                Text(viewModel.block.isMuted ? "Unmute Block" : "Mute Block")
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
          .padding(Style.cardPadding)
          .background(
            RoundedRectangle(cornerRadius: Style.cardCornerRadius, style: .continuous)
              .fill(Style.cardFill)
              .shadow(color: Style.cardShadowColor, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
          )

          // Spacer divider
          Divider()
            .padding(.vertical, Style.smallSpacing)

          // Bottom actions
          HStack(spacing: Style.rowSpacing) {
            Button {
              _ = canvasViewModel.duplicate(block: viewModel.block)
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "square.on.square")
                Text("Duplicate Block")
              }
              .foregroundColor(Style.accent)
              .padding(.horizontal, Style.bottomButtonHorizontalPadding)
              .padding(.vertical, Style.bottomButtonVerticalPadding)
              .background(
                Capsule()
                  .fill(Style.cardFill)
                  .shadow(color: Style.cardShadowColor, radius: Style.cardShadowRadius, x: Style.cardShadowX, y: Style.cardShadowY)
              )
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
              canvasViewModel.deleteBlockFromCanvas(block: viewModel.block)
              showingBlockDetailsView = false
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Delete Block")
              }
              .padding(.horizontal, Style.bottomButtonHorizontalPadding)
              .padding(.vertical, Style.bottomButtonVerticalPadding)
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
      .navigationTitle(viewModel.block.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { showingBlockDetailsView = false }
        }
        ToolbarItem(placement: .principal) {
          HStack(spacing: 10) {
            PreviewBlockView(model: viewModel.block)
              .frame(
                width: CanvasViewModel.blockSize,
                height: CanvasViewModel.blockSize)
              .scaleEffect(Style.blockPreviewScale)
            Text(viewModel.block.name)
              .font(.headline)
              .lineLimit(1)
              .truncationMode(.tail)
            Spacer()
          }
        }
      }
    }
  }

  // MARK: - Subviews

  @ViewBuilder
  private func rowWithSteppers(
    title: String,
    valueText: String,
    onDecrement: @escaping () -> Void,
    onIncrement: @escaping () -> Void
  ) -> some View {
    HStack(alignment: .center) {
      Text(title)
        .font(.headline)
      Spacer()
      HStack(spacing: 12) {
        circularButton(system: "chevron.down", action: onDecrement)
        Text(valueText)
          .frame(minWidth: 20)
        circularButton(system: "chevron.up", action: onIncrement)
      }
    }
  }

  @ViewBuilder
  private func circularButton(system: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: system)
        .foregroundColor(.primary)
        .frame(width: Style.circularButtonSize, height: Style.circularButtonSize)
        .background(
          Circle()
            .fill(Style.cardFill)
            .shadow(color: Style.smallShadowColor, radius: Style.smallShadowRadius, x: Style.smallShadowX, y: Style.smallShadowY)
        )
    }
    .buttonStyle(.plain)
  }
}

#Preview("Block Details") {
  // Local preview scaffolding
  @Previewable @State var showing = true

  let sampleBlock = Block.previewSample()
  let canvasVM = CanvasViewModel.previewMock()
  let detailsVM = BlockDetailsViewModel(block: sampleBlock)

  return BlockDetailsSheet(
    showingBlockDetailsView: $showing,
    canvasViewModel: canvasVM,
    viewModel: detailsVM,
    showLiveWaveform: false
  )
}

// MARK: - Preview helpers
private extension Block {
  static func previewSample() -> Block {
    // Construct a minimal Block suitable for previews using the Block initializer.
    let block = Block(
      id: Block.getNextBlockId(),
      location: CGPoint(x: 200, y: 200),
      color: .green,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "Samples/Fink/Drums/Funky_105a_timefix.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "Samples/Fink/Drums/Funky_105a_timefix.wav",
      isLibraryBlock: false
    )

    block.numBars = 1
    block.isMuted = false
    block.startOffset = 0
    block.volume = 0.75

    return block
  }
}

private extension CanvasViewModel {
  static func previewMock() -> CanvasViewModel {
    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: nil),
      musicEngine: MockMusicEngine(),
      canvasStore: nil,
      sampleSetStore: nil)

    return viewModel
  }
}
