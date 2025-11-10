//
//  BlockDetailsSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/9/25.
//

import SwiftUI

struct BlockDetailsSheet: View {
  let block: Block
  @Binding var showingBlockDetailsView: Bool
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          // Relative Path
          if let relativePath = block.relativePath, !relativePath.isEmpty {
            GroupBox("Relative Path") {
              Text(relativePath)
                .font(.footnote)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }

          // Actions
          GroupBox("Actions") {
            VStack(spacing: 12) {
              Button {
                viewModel.toggleMute(block: block)
              } label: {
                HStack {
                  Image(systemName: block.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                  Text(block.isMuted ? "Unmute Block" : "Mute Block")
                }
                .frame(maxWidth: .infinity)
              }
              .buttonStyle(.borderedProminent)

              Button(role: .destructive) {
                viewModel.deleteBlockFromCanvas(block: block)
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
      .navigationTitle(block.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { showingBlockDetailsView = false }
        }
        ToolbarItem(placement: .principal) {
          HStack {
            PreviewBlockView(model: block)
              .frame(
                width: CanvasViewModel.blockSize,
                height: CanvasViewModel.blockSize)
              .scaleEffect(0.5)
            Text(block.name)
              .font(.headline)
            Spacer()
          }
        }
      }
    }
  }
}
