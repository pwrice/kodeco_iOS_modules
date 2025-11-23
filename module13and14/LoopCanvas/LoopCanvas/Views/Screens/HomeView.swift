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

  enum HomeViewLinks {
    case newSong
    case allSongs
    case recents
    case shared
    case favorites
  }

  var body: some View {
    NavigationStack {
      List {
        NavigationLink(value: HomeViewLinks.newSong) {
          HStack {
            Text("New Song")
              .foregroundColor(Color("TextLabelColor"))
          }
        }
        NavigationLink(value: HomeViewLinks.allSongs) {
          HStack {
            Text("Saved Songs")
              .foregroundColor(Color("TextLabelColor"))
          }
        }
        /*  TODO - implement these screens eventually
        NavigationLink(value: HomeViewLinks.recents) {
          HStack {
            Text("Recents")
              .foregroundColor(Color("TextLabelColor"))
          }
        }
        NavigationLink(value: HomeViewLinks.shared) {
          HStack {
            Text("Shared")
              .foregroundColor(Color("TextLabelColor"))
          }
        }
        NavigationLink(value: HomeViewLinks.favorites) {
          HStack {
            Text("Favorites")
              .foregroundColor(Color("TextLabelColor"))
          }
        }
         */
      }
      .navigationTitle(Text("Loop Canvas"))
      .navigationDestination(for: HomeViewLinks.self) { linkValue in
        switch linkValue {
        case .newSong:
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
        case .allSongs:
          if let sampleSetStore = canvasStore.sampleSetStore {
            SongListView(
              canvasStore: canvasStore,
              sampleSetStore: sampleSetStore,
              screenName: "Saved Songs")
          }
        default:
          PlaceHolderView()
        }
      }
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
