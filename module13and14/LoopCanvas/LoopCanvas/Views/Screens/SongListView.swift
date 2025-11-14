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
  let screenName: String

  var body: some View {
    VStack {
      if canvasStore.savedCanvases.isEmpty {
        Spacer()
        Text("No saved songs yet")
        Spacer()
        Spacer()
      } else {
        ScrollView {
          VStack {
            CanvasesGridView(canvasStore: canvasStore, sampleSetStore: sampleSetStore)
          }
        }
      }
    }
    .navigationTitle(Text(screenName))
    .onAppear {
      canvasStore.reloadSavedCanvases()
    }
  }
}

struct CanvasesGridView: View {
  @ObservedObject var canvasStore: CanvasStore
  let sampleSetStore: SampleSetStore

  var resultColumns: [GridItem] {
    [
      GridItem(.flexible(minimum: 150)),
      GridItem(.flexible(minimum: 150))
    ]
  }

  var body: some View {
    LazyVGrid(columns: resultColumns) {
      ForEach(canvasStore.savedCanvases) { savedCanvas in
        NavigationLink(value: savedCanvas) {
          SavedCanvasView(savedCanvasModel: savedCanvas)
        }
      }
    }
    .navigationDestination(for: SavedCanvasModel.self) { savedCanvas in
      let canvasViewModel = CanvasViewModel(
        canvasModel: CanvasModel(
          sampleSetStore: sampleSetStore
        ),
        musicEngine: AudioKitMusicEngine(),
        canvasStore: canvasStore,
        sampleSetStore: sampleSetStore,
        songNameToLoad: savedCanvas.name)
      CanvasView(viewModel: canvasViewModel)
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
      // Portrait Preview
      NavigationStack {
        SongListView(
          canvasStore: CanvasStore(
            debugSavedCanvases: savedCanvases,
            sampleSetStore: sampleSetStore),
          sampleSetStore: sampleSetStore,
          screenName: "Saved Songs"
        )
      }
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Preview No Songs
      NavigationStack {
        SongListView(
          canvasStore: CanvasStore(
            debugSavedCanvases: [],
            sampleSetStore: sampleSetStore),
          sampleSetStore: sampleSetStore,
          screenName: "Saved Songs"
        )
      }
      .previewDisplayName("Portrait Mode - No Songs")
      .previewInterfaceOrientation(.portrait)

      NavigationStack {
        SongListView(
          canvasStore: CanvasStore(
            debugSavedCanvases: savedCanvases,
            sampleSetStore: sampleSetStore),
          sampleSetStore: sampleSetStore,
          screenName: "Saved Songs"
        )
      }
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      NavigationStack {
        SongListView(
          canvasStore: CanvasStore(
            debugSavedCanvases: savedCanvases,
            sampleSetStore: sampleSetStore),
          sampleSetStore: sampleSetStore,
          screenName: "Saved Songs"
        )
      }
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
