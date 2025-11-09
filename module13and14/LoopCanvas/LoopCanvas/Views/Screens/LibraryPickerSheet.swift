//
//  LibraryPickerSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/7/25.
//
//

import SwiftUI

struct LibraryPickerSheet: View {
  @ObservedObject var library: Library
  var addBlockTapPosition: CGPoint?
  var viewModel: CanvasViewModel
  @Binding var showingLibraryPickerView: Bool

  var body: some View {
    NavigationView {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
          ForEach(library.categories, id: \.name) { category in
            Section {
              ForEach(category.blocks) { blockModel in
                HStack(alignment: .center, spacing: 12) {
                  LibraryPickerBlockView(model: blockModel)
                    .frame(width: 56, height: 56)
                  Text(blockModel.relativePath ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                  Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .onTapGesture {
                  if let addBlockTapPosition = addBlockTapPosition {
                    _ = viewModel.addBlockToCanvasOnGrid(
                      block: blockModel.instantiateCopyWith(
                        location: addBlockTapPosition,
                        isLibraryBlock: false))
                  }
                  showingLibraryPickerView = false
                }
                Divider()
                  .padding(.leading, 16 + 56 + 12) // indent under the text
              }
            } header: {
              HStack {
                Text(category.name)
                  .font(.headline)
                Spacer()
              }
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(Color(.systemBackground))
            }
          }
        }
      }
      .navigationBarTitle(Text("Add Loop Block"), displayMode: .inline)
      .navigationBarItems(
        trailing: Button("Done") {
          showingLibraryPickerView = false
        }
      )
    }
  }
}

struct LibraryPickerSheet_Previews: PreviewProvider {
  static var previews: some View {
    let sampleSetStore = SampleSetStore()
    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(
        sampleSetStore: sampleSetStore),
      musicEngine: MockMusicEngine(),
      canvasStore: CanvasStore(sampleSetStore: sampleSetStore),
      sampleSetStore: sampleSetStore
    )


    Group {
      // Portrait Preview
      LibraryPickerSheet(
        library: viewModel.canvasModel.library,
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      LibraryPickerSheet(
        library: viewModel.canvasModel.library,
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      LibraryPickerSheet(
        library: viewModel.canvasModel.library,
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
