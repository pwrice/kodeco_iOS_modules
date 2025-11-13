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
  let showLiveWaveform:Bool

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Waveform view
          ZStack(alignment: .leading) {
            if showLiveWaveform {
              Waveform(samples: viewModel.samples)
                .foregroundColor(.green) // TODO - move these colors into assets
            } else {
              Spacer()
            }

          }
          .background(.black)
          .frame(height: 70)

          // Bars selection
          GroupBox("Bars") {
            HStack {
              Text("Number of Bars")
              Spacer()
              Menu {
                // Generate options from 1 through maxNumBars
                // TOOD - why is viewModel.block.maxNumBars 1 ?
                ForEach(1..<(viewModel.block.maxNumBars + 1), id: \.self) { bars in
                  Button("\(bars)") {
                    // Update the model when a selection is made
                    canvasViewModel.update(numBars:bars, for: viewModel.block)
                  }
                }
              } label: {
                HStack(spacing: 6) {
                  Text("\(viewModel.block.numBars)")
                  Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                )
              }
            }
          }

          // Actions
          GroupBox("Actions") {
            VStack(spacing: 12) {
              Button {
                canvasViewModel.toggleMute(block: viewModel.block)
              } label: {
                HStack {
                  Image(systemName: viewModel.block.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                  Text(viewModel.block.isMuted ? "Unmute Block" : "Mute Block")
                }
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)

              Button(role: .destructive) {
                canvasViewModel.deleteBlockFromCanvas(block: viewModel.block)
                showingBlockDetailsView = false
              } label: {
                HStack {
                  Image(systemName: "trash")
                  Text("Delete Block")
                }
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(.bordered)
            }
          }

          Spacer(minLength: 8)
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
          HStack {
            PreviewBlockView(model: viewModel.block)
              .frame(
                width: CanvasViewModel.blockSize,
                height: CanvasViewModel.blockSize)
              .scaleEffect(0.5)
            Text(viewModel.block.name)
              .font(.headline)
            Spacer()
          }
        }
      }
    }
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
      icon: "circle", // any supported icon name used in your app
      loopURL: URL(fileURLWithPath: "Samples/Fink/Drums/Funky_105a_timefix.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "Samples/Fink/Drums/Funky_105a_timefix.wav",
      isLibraryBlock: false
    )

    // Configure additional preview-only properties
    block.numBars = 1
    block.isMuted = false

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
