//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI
import ImageIO


struct CanvasView: View {
  @StateObject var viewModel: CanvasViewModel
  @State var showingRenameSongView = false
  @State var showingDownloadGenresView = false
  @State var showingLibraryPickerView = false
  @State var addBlockTapPosition: CGPoint?

  var canvasBlocksView: some View {
    CanvasBlocksView(viewModel: viewModel)
  }

  var body: some View {
    ZStack {
      ScrollView([.horizontal, .vertical]) {
        ZStack {
          BackgroundDots(addBlockTapGridPosition: viewModel.addBlockTapGridPosition)

          canvasBlocksView

          GeometryReader { proxy in
            let offset = proxy.frame(in: .named("CanvasCoordinateSpace")).origin
            // This prefernces method to calculate the scroll offset
            // seems a bit hacky. Is there a better way?
            Color.clear.preference(
              key: ViewOffsetKey.self,
              value: CGPoint(x: offset.x, y: offset.y))
          }
        }
        .background(Color("CanvasBackgroundColor"))
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
      }
      .defaultScrollAnchor(.zero) // TODO - when setting this to 0, the initial scroll
                                  // view offset is incorrect until the user interacts
      .coordinateSpace(name: "CanvasCoordinateSpace")
      .onPreferenceChange(ViewOffsetKey.self) {
        viewModel.canvasScrollOffset = $0
      }
      .onTapGesture(coordinateSpace: .local) { location in
        addBlockTapPosition = location
        viewModel.addBlockTapGridPosition = CanvasViewModel.gridPosition(for: location)
        showingLibraryPickerView = true
      }

      UIOverlayView(viewModel: viewModel)
    }
    .coordinateSpace(name: "ViewportCoorindateSpace")
    .onAppear {
      viewModel.onViewAppear()
    }
    .onChange(of: showingLibraryPickerView) { _, newValue in
      if newValue == false {
        viewModel.addBlockTapGridPosition = nil
      }
    }
    .navigationBarItems(
      trailing: Menu {
        Button("Rename ...") {
          if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
            viewModel.canvasSnapshot = snapshotImage
            showingRenameSongView = true
          }
        }
        Button("Save") {
          // If the song hasnt been saved yet, get its thumbnail and make the user
          // name it.
          if viewModel.canvasModel.thumnail == nil {
            if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
              viewModel.canvasSnapshot = snapshotImage
              showingRenameSongView = true
            }
          } else {
            viewModel.saveSong()
          }
        }
        Button("Reload") {
          viewModel.loadSong()
        }
        Menu {
          // Current selection shown as a disabled item
          Button(action: {}, label: {
            HStack {
              Text("Current: \(viewModel.selectedSampleSetName)")
              Spacer()
              Image(systemName: "checkmark")
            }
          })
          .disabled(true)

          // List all local sample sets as selectable items
          ForEach(viewModel.sampleSetStore.localSampleSets.map { $0.name }, id: \.self) { name in
            Button(action: {
              if name != viewModel.selectedSampleSetName {
                viewModel.selectedSampleSetName = name
                viewModel.loadSampleSetAndResetCanvas(sampleSetName: name)
              }
            }, label: {
              HStack {
                Text(name)
                if name == viewModel.selectedSampleSetName {
                  Spacer()
                  Image(systemName: "checkmark")
                }
              }
            })
          }
        } label: {
          Label("Sample Set", systemImage: "music.note.list")
        }
        Button("Clear Canvas") {
          viewModel.clearCanvas()
        }
        Button("Download Genres ...") {
          showingDownloadGenresView = true
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      })
    .sheet(isPresented: $showingRenameSongView, content: {
      RenameSongSheet(viewModel: viewModel, showingRenameSongView: $showingRenameSongView)
    })
    .sheet(isPresented: $showingDownloadGenresView, content: {
      DownloadGenresSheet(
        viewModel: viewModel,
        store: viewModel.sampleSetStore,
        showingDownloadGenresView: $showingDownloadGenresView)
    })
    .sheet(isPresented: $showingLibraryPickerView, content: {
      LibraryPickerSheet(
        library: viewModel.canvasModel.library,
        addBlockTapPosition: addBlockTapPosition,
        viewModel: viewModel,
        showingLibraryPickerView: $showingLibraryPickerView)
      .presentationDetents([.medium])
    })
  }

  func snapshot(snapshotView: some View) -> UIImage? {
    let imagerenderer = ImageRenderer(
      content: VStack {
        snapshotView
      }
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
    )
    return viewModel.getThumbnailFromScreenShot(screenShotImage: imagerenderer.cgImage)
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGPoint
  static var defaultValue = CGPoint.zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    let next = nextValue()
    value = CGPoint(x: value.x + next.x, y: value.y + next.y)  // value += nextValue()
  }
}

struct CanvasBlocksView: View {
  @ObservedObject var viewModel: CanvasViewModel

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?

  func blockDragGesture(block: Block) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($dragStartLocation) { _, startLocation, _ in
        // Called before onChanged
        startLocation = startLocation ?? block.location
      }
      .onChanged { value in
        var newLocation = dragStartLocation ?? block.location
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockDragLocation(block: block, location: newLocation)
      }
      .onEnded { _ in
        _ = viewModel.dropBlockOnCanvas(block: block)
      }
  }

  var body: some View {
    ZStack { // This is just the blocks
      Spacer()
      ForEach(viewModel.allBlocks) { blockModel in
        PositionedBlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
      }
    }
  }
}

struct BackgroundDots: View {
  let addBlockTapGridPosition: CGPoint?

  func highlightBlock(x: Int, y: Int) -> Bool {
    return (addBlockTapGridPosition?.x == CGFloat(x) &&
     addBlockTapGridPosition?.y == CGFloat(y))
  }

  var body: some View {
    ZStack { // Background dots
      let dotSpacing = CanvasViewModel.gridSpacing()
      let (numCols, numRows) = CanvasViewModel.gridDimensions()
      ForEach(0..<numCols, id: \.self) { hInd in
        ForEach(0..<numRows, id: \.self) { vInd in
          ZStack {
            RoundedRectangle(cornerRadius: 10) // TODO - make this a constant
              .fill(.clear)
              .stroke(.gray, lineWidth: 2) // TODO - put these colors into Assets
              .opacity(highlightBlock(x: hInd, y: vInd) ? 1 : 0)
              .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
              .position(CGPoint(
                x: (CGFloat(hInd) * dotSpacing) + (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2,
                y: (CGFloat(vInd) * dotSpacing) + (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing) / 2
              ))
            Rectangle()
              .foregroundColor(.gray)
              .frame(width: 2, height: 2)
              .position(CGPoint(
                x: CGFloat(hInd) * dotSpacing,
                y: CGFloat(vInd) * dotSpacing))
          }
        }
      }
    }
  }
}

struct UIOverlayView: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    VStack {
      Spacer()
    }
  }
}


struct CanvasView_Previews: PreviewProvider {
  static var previews: some View {
    let sampleSetStore = SampleSetStore()
    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: MockMusicEngine(),
      canvasStore: CanvasStore(sampleSetStore: sampleSetStore),
      sampleSetStore: sampleSetStore
    )

    Group {
      // Portrait Preview
      NavigationView {
        CanvasView(viewModel: viewModel)
      }
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      NavigationView {
        CanvasView(viewModel: viewModel)
      }
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      NavigationView {
        CanvasView(viewModel: viewModel)
      }
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}


// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml

// UPDATED TODO - Nov 2025
// - remove library view and related functionality
//   - add way in pulldown menu to switch genres
//   - fix tests to exercise adding / removing blocks
// - add context menu for tapping on block
//   - delete loop
//   - mute loop
//   - add selection state for block
//   - add extend loop to multiple bars (or shorten)
// - add multi-bar support for loops
//   - extended rectangle renderer
//   - incorporate length into model
// - add animation for block after it is dropped till the next bar when playback starts
// - add ability to import your own samples from documents folder
//   - how to deal with tempo adjustment and loop length?
// - figure out how to select a group and set group properties (mute etc...)

// MULTI-USER
// hook up shareplay so multiple users can edit a canvas at the same time

// AUv3
// make AUv3 plugin so you can record into loops from other audio apps


// Library TODO
// [DONE] Add symbols to blocks to differentiate w/in a category
// [DONE] Add picker to library to allow switching between categories
// [DONE] - add picker UI
// [DONE] - swap out blocks when picker choice is made
// [DONE] - add dot grid background to canvas (so it is easier to see scrolling)
// [DONE] Refactor views into smaller subviews

// Save / Delete
// [DONE] - name song on save
// [DONE] - take screenshot for song to use as thumb
// [DONE] - save song and thumbnail to documents directory
// [DONE] - load song and thumbnail from documents directory
// [DONE]- load correct library for song
// [DONE]- build all songs view


// [DONE]- add new genre's of music
// [DONE]- add ability to switch genres
// [DONE]- add ability to download genres from server
// [DONE]-- add download genre view
// [DONE]-- adding loading state spinner when getting initial response
// [DONE]-- mark genres as downloaded or not downloaded
// [DONE]-- add button to remove download (and add stub calls for remove download functionality)
// [DONE]-- upload full genres files to S3
// [DONE]-- implement background downloader w progress
// [DONE]-- display progress is genre download sheet
// [DONE]-- fix bug where library blocks appear on canvas during initial transition
// [DONE]-- fix bug where you can delete currently playing genre

// Refactor all views so they easily work with preview w/ mock data


// Capstone project requirements
// -- handle network errors gracefully (toast?)
// -- make app work in landscape and portrait mode
//    -- canvas view
//   [DONE]-- make library blocks reset location on rotation
//   [DONE]-- make library 1 row of blocks
//     -- make portrait mode work upside-down
//   [DONE]-- home view
//   [DONE]-- song list view
//   [DONE]-- download genres sheet
//   [DONE]-- rename song sheet
//   [DONE]-- place holder view
// -- make app work in light and dark mode
// -- add SwiftUI animation somewhere
// -- find a place to add tab navigation
// -- add UI tests

// Add more comprehensive tests (+ view model refactoring to make this easier)


// Update tests for library behavior
// context tap to select block
// block contextual menu
// add delete block

// context tab to select block group
// - tap near group
// group context menu
// delete group etc..

// add navigation tabs below (per freeform)
// - loops
// - sample triggers / effects (add search here)
//   - hook up the api search here

// How to make the library work with different phone sizes?


// GB genre BPMs - electronica - 133.0 funk - 115.0
