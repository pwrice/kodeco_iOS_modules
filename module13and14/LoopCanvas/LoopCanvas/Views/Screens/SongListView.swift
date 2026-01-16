//
//  SongListView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 8/14/24.
//

import SwiftUI

struct SongListView: View {
  @ObservedObject var canvasStore: CanvasStore
  let sampleSetStore: SampleSetStore
  @Binding var isPresented: Bool
  let onSelect: (SavedCanvasModel) -> Void

  init(canvasStore: CanvasStore, sampleSetStore: SampleSetStore, isPresented: Binding<Bool>, onSelect: @escaping (SavedCanvasModel) -> Void) {
    self._canvasStore = ObservedObject(initialValue: canvasStore)
    self.sampleSetStore = sampleSetStore
    self._isPresented = isPresented
    self.onSelect = onSelect
  }

  var body: some View {
    NavigationView {
      VStack {
        if canvasStore.savedCanvases.isEmpty {
          Spacer()
          Text("No saved songs yet")
          Spacer()
          Spacer()
        } else {
          ScrollView {
            VStack {
              CanvasesSelectGridView(canvasStore: canvasStore) { saved in
                onSelect(saved)
                isPresented = false
              }
            }
          }
        }
      }
      .navigationTitle("Load Canvas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { isPresented = false }
        }
      }
      .onAppear {
        canvasStore.reloadSavedCanvases()
      }
    }
  }
}

struct CanvasesSelectGridView: View {
  @ObservedObject var canvasStore: CanvasStore
  var onSelect: (SavedCanvasModel) -> Void

  var resultColumns: [GridItem] {
    [
      GridItem(.flexible(minimum: 150)),
      GridItem(.flexible(minimum: 150))
    ]
  }

  var body: some View {
    LazyVGrid(columns: resultColumns) {
      ForEach(canvasStore.savedCanvases) { savedCanvas in
        Button(action: { onSelect(savedCanvas) }) {
          SavedCanvasView(savedCanvasModel: savedCanvas)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

struct SavedCanvasView: View {
  let savedCanvasModel: SavedCanvasModel

  var body: some View {
    VStack {
      Image(uiImage: savedCanvasModel.thumnail)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 140, height: 100)
      Text(savedCanvasModel.name)
        .lineLimit(1)
        .truncationMode(.tail)
      Spacer()
    }
    .padding(5)
    .background(Color("SavedCanvasBackgroundColor"))
    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.33), radius: 10, x: 0, y: 5)
  }
}


struct SongListView_Previews: PreviewProvider {
  static var previews: some View {
    let sampleSetStore = SampleSetStore(withMockResults: "Samples/SampleSetIndex.json")

    let savedCanvases = [
      SavedCanvasModel(
        index: 0,
        name: "Test Canvas 1",
        thumnail: UIImage(systemName: "photo")!),
      SavedCanvasModel(
        index: 1,
        name: "Test Canvas 2",
        thumnail: UIImage(systemName: "photo")!),
      SavedCanvasModel(
        index: 2,
        name: "Test Canvas 3",
        thumnail: UIImage(systemName: "photo")!),
      SavedCanvasModel(
        index: 3,
        name: "Test Canvas 4",
        thumnail: UIImage(systemName: "photo")!),
      SavedCanvasModel(
        index: 4,
        name: "Test Canvas 5",
        thumnail: UIImage(systemName: "photo")!)
    ]

    Group {
      // Non-empty sheet preview
      SongListView(
        canvasStore: CanvasStore(
          debugSavedCanvases: savedCanvases,
          sampleSetStore: sampleSetStore),
        sampleSetStore: sampleSetStore,
        isPresented: .constant(true),
        onSelect: { _ in }
      )
      .previewDisplayName("Sheet Mode - Non-empty")

      // Empty sheet preview
      SongListView(
        canvasStore: CanvasStore(
          debugSavedCanvases: [],
          sampleSetStore: sampleSetStore),
        sampleSetStore: sampleSetStore,
        isPresented: .constant(true),
        onSelect: { _ in }
      )
      .previewDisplayName("Sheet Mode - Empty")

      // Dark mode sheet preview
      SongListView(
        canvasStore: CanvasStore(
          debugSavedCanvases: savedCanvases,
          sampleSetStore: sampleSetStore),
        sampleSetStore: sampleSetStore,
        isPresented: .constant(true),
        onSelect: { _ in }
      )
      .previewDisplayName("Sheet Mode - Dark Mode")
      .preferredColorScheme(.dark)

      // Landscape sheet preview
      SongListView(
        canvasStore: CanvasStore(
          debugSavedCanvases: savedCanvases,
          sampleSetStore: sampleSetStore),
        sampleSetStore: sampleSetStore,
        isPresented: .constant(true),
        onSelect: { _ in }
      )
      .previewDisplayName("Sheet Mode - Landscape")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
