//
//  HomeView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct HomeView: View {
  @StateObject var canvasStore = CanvasStore(
    sampleSetStore: SampleSetStore()
  )

  var body: some View {
    NavigationStack {
      let canvasViewModel = CanvasViewModel(
        canvasModel: CanvasModel(
          sampleSetStore: canvasStore.sampleSetStore),
        musicEngine: AudioKitMusicEngine(),
        canvasStore: canvasStore,
        sampleSetStore: canvasStore.sampleSetStore,
        canvasMessageStore: CanvasMessageStore(
          groupSessionWrapper: ConcreteGroupSessionWrapper())
      )
      CanvasView(viewModel: canvasViewModel)
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Portrait Preview
      HomeView()
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      HomeView()
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      HomeView()
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
