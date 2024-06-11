//
//  ContentView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI

struct ContentView: View {
  @StateObject var canvasViewModel = CanvasViewModel(
    canvasModel: CanvasModel(), musicEngine: AudioKitMusicEngine())
  var body: some View {
    CanvasView(viewModel: canvasViewModel)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
