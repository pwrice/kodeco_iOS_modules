//
//  BlockDetailsSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/9/25.
//

import SwiftUI
import Waveform

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
        VStack(alignment: .leading, spacing: 16) {
          // Card
          VStack(alignment: .leading, spacing: 16) {
            // Waveform header
            ZStack {
              RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                  Group {
                    if showLiveWaveform {
                      Waveform(samples: viewModel.samples)
                        .foregroundColor(.green)
                        .padding(12)
                    } else {
                      Color.clear
                    }
                  }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .frame(height: 100)

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
            VStack(alignment: .leading, spacing: 8) {
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
              .foregroundColor(.blue)
              .padding(.horizontal, 16)
              .padding(.vertical, 10)
              .background(
                Capsule()
                  .fill(Color(.systemBackground))
                  .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 6, x: 0, y: 3)
              )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
          }
          .padding(16)
          .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .fill(Color(.systemBackground))
              .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 10, x: 0, y: 6)
          )

          // Spacer divider
          Divider()
            .padding(.vertical, 8)

          // Bottom actions
          HStack(spacing: 16) {
            Button {
              _ = canvasViewModel.duplicate(block: viewModel.block)
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "square.on.square")
                Text("Duplicate Block")
              }
              .foregroundColor(.blue)
              .padding(.horizontal, 18)
              .padding(.vertical, 12)
              .background(
                Capsule()
                  .fill(Color(.systemBackground))
                  .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 10, x: 0, y: 6)
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
              .padding(.horizontal, 18)
              .padding(.vertical, 12)
              .background(
                Capsule()
                  .fill(Color(.systemBackground))
                  .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 10, x: 0, y: 6)
              )
            }
            .buttonStyle(.plain)
          }
        }
        .padding()
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
              .scaleEffect(0.5)
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
        .frame(width: 30, height: 30)
        .background(
          Circle()
            .fill(Color(.systemBackground))
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.12), radius: 6, x: 0, y: 3)
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
    let sampleSetStore = SampleSetStore(withMockResults: "Samples/SampleSetIndex.json")

    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: MockMusicEngine(),
      canvasStore: CanvasStore(sampleSetStore: sampleSetStore),
      sampleSetStore: sampleSetStore)

    return viewModel
  }
}
