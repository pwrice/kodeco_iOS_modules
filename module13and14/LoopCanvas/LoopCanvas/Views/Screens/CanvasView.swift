//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI
import ImageIO
import CoreGraphics


struct CanvasView: View {
  @StateObject var viewModel: CanvasViewModel
  @State var showingRenameSongView = false
  @State var showingDownloadGenresView = false
  @State var showingLibraryPickerView = false
  @State var showingBlockDetailsView = false
  @State var showingBlockGroupDetailsView = false
  @State var addBlockTapPosition: CGPoint?
  @State var showingSongListView = false
  @State private var canvasRect: CGRect = .zero
  @State private var viewPortRect: CGRect = .zero

  var body: some View {
    GeometryReader { screenGeo in            // <---- NEW: top-level GeometryReader
      ZStack {
        ScrollView([.horizontal, .vertical]) {
          ZStack {
            BackgroundDots(addBlockTapGridPosition: viewModel.addBlockTapGridPosition)

            // Blocks layer
            canvasBlocksView

            // Effects layer
            CanvasEffectsView(viewModel: viewModel)

            // Single geometry "probe" to calculate scroll offset & viewport
            GeometryReader { proxy in
              let frame = proxy.frame(in: .named("CanvasCoordinateSpace"))

              // frame.origin is usually (0,0) at content origin, then becomes negative as you scroll.
              // We:
              //  - use frame.origin as scroll offset
              //  - build the viewport rect in canvas/content coordinates from it

              let scrollOffset = frame.origin
              let viewportRectInCanvas = CGRect(
                origin: CGPoint(
                  x: -scrollOffset.x,
                  y: -scrollOffset.y
                ),
                size: screenGeo.size
              )

              // Full canvas rect in its own coordinates
              let fullCanvasRect = CGRect(
                origin: .zero,
                size: CGSize(
                  width: CanvasViewModel.canvasWidth,
                  height: CanvasViewModel.canvasWidth
                )
              )

              Color.clear
                .preference(key: ViewOffsetKey.self, value: scrollOffset)
                .preference(key: CanvasRectKey.self, value: fullCanvasRect)
                .preference(key: ViewPortRectKey.self, value: viewportRectInCanvas)
            }
          }
          .background(Color("CanvasBackgroundColor"))
          .frame(
            width: CanvasViewModel.canvasWidth,
            height: CanvasViewModel.canvasWidth
          )
        }
        .scrollDisabled(viewModel.selectedTool == .effects)
        .defaultScrollAnchor(.zero)
        .coordinateSpace(name: "CanvasCoordinateSpace")  // <---- coordinate space lives on ScrollView

        .onPreferenceChange(ViewOffsetKey.self) { offset in
          viewModel.canvasScrollOffset = offset
        }
        .onPreferenceChange(CanvasRectKey.self) { rect in
          self.canvasRect = rect
          viewModel.updateVisibleEffectsRect(
            canvasRect: rect,
            viewPortRect: self.viewPortRect,
          )
        }
        .onPreferenceChange(ViewPortRectKey.self) { rect in
          viewModel.updateVisibleEffectsRect(
            canvasRect: self.canvasRect,
            viewPortRect: rect,
          )
        }
        .onTapGesture(coordinateSpace: .local) { location in
          guard viewModel.selectedTool == .loop else { return }

          // Only used for Loop tool; when Effects/Visuals are selected, taps would be handled differently
          addBlockTapPosition = location
          viewModel.addBlockTapGridPosition = CanvasViewModel.gridPosition(for: location)
          showingLibraryPickerView = true
        }

        // Floating tool bar overlay
        FloatingToolbarOverlay(viewModel: viewModel)
      }
      .coordinateSpace(name: "ViewportCoordinateSpace") // keep if you actually use this elsewhere
      .onAppear {
        viewModel.onViewAppear()
      }
      .onChange(of: showingLibraryPickerView) { _, newValue in
        if newValue == false {
          viewModel.addBlockTapGridPosition = nil
        }
      }
      .onChange(of: showingBlockDetailsView) { _, newValue in
        if newValue == false {
          viewModel.unselectCurrentlySelectedBlock()
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          AppMenuView(
            viewModel: viewModel,
            showingSongListView: $showingSongListView,
            showingRenameSongView: $showingRenameSongView,
            canvasBlocksView: canvasBlocksView
          )
        }
        ToolbarItem(placement: .principal) {
          TopCenterControls(viewModel: viewModel)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack {
            SharePlayControls(viewModel: viewModel)
            CanvasMenuView(
              viewModel: viewModel,
              showingRenameSongView: $showingRenameSongView,
              showingDownloadGenresView: $showingDownloadGenresView,
              canvasBlocksView: canvasBlocksView
            )
          }
        }
      }
      .sheet(isPresented: $showingRenameSongView, content: {
        RenameSongSheet(
          viewModel: viewModel,
          showingRenameSongView: $showingRenameSongView
        )
      })
      .sheet(isPresented: $showingDownloadGenresView) {
        if let sampleSetStore = viewModel.sampleSetStore {
          DownloadGenresSheet(
            viewModel: viewModel,
            store: sampleSetStore,
            showingDownloadGenresView: $showingDownloadGenresView
          )
        }
      }
      .sheet(isPresented: $showingSongListView) {
        if let canvasStore = viewModel.canvasStore,
           let sampleSetStore = viewModel.sampleSetStore {
          SongListView(
            canvasStore: canvasStore,
            sampleSetStore: sampleSetStore,
            isPresented: $showingSongListView
          ) { saved in
            viewModel.loadSong(name: saved.name)
          }
        }
      }
      .sheet(isPresented: $showingLibraryPickerView) {
        LibraryPickerSheet(
          library: viewModel.canvasModel.library,
          addBlockTapPosition: addBlockTapPosition,
          viewModel: viewModel,
          showingLibraryPickerView: $showingLibraryPickerView
        )
        .presentationDetents([.medium])
      }
      .sheet(isPresented: $showingBlockDetailsView) {
        if let blockDetailsViewModel = viewModel.blockDetailsViewModel {
          BlockDetailsSheet(
            showingBlockDetailsView: $showingBlockDetailsView,
            canvasViewModel: viewModel,
            viewModel: blockDetailsViewModel,
            showLiveWaveform: true
          )
          .presentationDetents([.medium])
        }
      }
      .sheet(isPresented: $showingBlockGroupDetailsView) {
        if let selectedBlockGroup = viewModel.selectedBlockGroup {
          BlockGroupDetailsSheet(
            canvasViewModel: viewModel,
            group: selectedBlockGroup,
            isPresented: $showingBlockGroupDetailsView
          )
          .presentationDetents([.medium])
        }
      }
    }
  }

  var canvasBlocksView: some View {
    CanvasBlocksView(
      viewModel: viewModel,
      showingBlockDetailsView: $showingBlockDetailsView,
      showingBlockGroupDetailsView: $showingBlockGroupDetailsView)
  }

  var localSampleSets: [LocalSampleSet] {
    viewModel.sampleSetStore?.localSampleSets ?? []
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

struct TopCenterControls: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    HStack(spacing: 12) {
      Button(action: { viewModel.togglePlayback() }) {
        ZStack {
          if viewModel.isPlaying {
            Image(systemName: "stop.fill")
          } else {
            Image(systemName: "play.fill")
          }
        }
        .frame(width: 22, height: 22)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(viewModel.isPlaying ? "Stop" : "Play")
      Divider()
      Text("Set: \(viewModel.canvasTitle)")
        .font(.headline)
        .lineLimit(1)
      Divider()
      Text("\(viewModel.canvasBPM) BPM")
        .font(.subheadline)
    }
  }
}

struct AppMenuView: View {
  @ObservedObject var viewModel: CanvasViewModel
  @Binding var showingSongListView: Bool
  @Binding var showingRenameSongView: Bool
  let canvasBlocksView: AnyView

  init(viewModel: CanvasViewModel, showingSongListView: Binding<Bool>, showingRenameSongView: Binding<Bool>, canvasBlocksView: some View) {
    self._showingSongListView = showingSongListView
    self._showingRenameSongView = showingRenameSongView
    self.viewModel = viewModel
    self.canvasBlocksView = AnyView(canvasBlocksView)
  }

  var body: some View {
    Menu {
      Button("New Canvas") {
        viewModel.newSong()
      }
      Button("Load Canvas") {
        showingSongListView = true
      }
      Button("Save Canvas") {
        if viewModel.canvasModel.thumnail == nil {
          if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
            viewModel.canvasSnapshot = snapshotImage
            showingRenameSongView = true
          }
        } else {
          viewModel.saveSong()
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal")
    }
  }

  private func snapshot(snapshotView: some View) -> UIImage? {
    let imagerenderer = ImageRenderer(
      content: VStack {
        snapshotView
      }
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
    )
    return viewModel.getThumbnailFromScreenShot(screenShotImage: imagerenderer.cgImage)
  }
}

struct SharePlayControls: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    Group {
      if viewModel.canvasMessageStore?.eligibleToStartSharing == true {
        Button {
          viewModel.startSharing()
        } label: {
          Image(systemName: "shareplay")
        }
      }
      if viewModel.canvasMessageStore?.sharePlaySessionActive == true {
        SharePlayMenuView(viewModel: viewModel)
      }
    }
  }
}

struct CanvasMenuView: View {
  @ObservedObject var viewModel: CanvasViewModel
  @Binding var showingRenameSongView: Bool
  @Binding var showingDownloadGenresView: Bool
  let canvasBlocksView: AnyView

  init(viewModel: CanvasViewModel, showingRenameSongView: Binding<Bool>, showingDownloadGenresView: Binding<Bool>, canvasBlocksView: some View) {
    self.viewModel = viewModel
    self._showingRenameSongView = showingRenameSongView
    self._showingDownloadGenresView = showingDownloadGenresView
    self.canvasBlocksView = AnyView(canvasBlocksView)
  }

  var body: some View {
    Menu {
      Button("Rename ...") {
        if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
          viewModel.canvasSnapshot = snapshotImage
          showingRenameSongView = true
        }
      }
      Button("Save") {
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
        viewModel.reloadSong()
      }
      Menu {
        ForEach(localSampleSets.map { $0.name }, id: \.self) { name in
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
    }
  }

  private var localSampleSets: [LocalSampleSet] {
    viewModel.sampleSetStore?.localSampleSets ?? []
  }

  private func snapshot(snapshotView: some View) -> UIImage? {
    let imagerenderer = ImageRenderer(
      content: VStack {
        snapshotView
      }
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
    )
    return viewModel.getThumbnailFromScreenShot(screenShotImage: imagerenderer.cgImage)
  }
}

struct SharePlayMenuView: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    Menu {
      if let sharePlayUsers = viewModel.sharePlayUsers {
        ForEach(sharePlayUsers, id: \.id) { sharePlayUser in
          Button(action: {}, label: {
            HStack {
              Text(sharePlayUser.name)
              Spacer()
              Image(systemName: "person")
            }
          })
          .disabled(true)
        }
      }

      Button("Push Snapshot") {
        viewModel.sendCanvasModelSnapshot()
      }

      Button("Request Snapshot") {
        // TODO - add this - so request a snapshot from the host
      }

      Button("Reset Session") {
        viewModel.resetSharePlaySession()
      }
    } label: {
      Image(systemName: "person.2.fill")
    }
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGPoint
  static var defaultValue = CGPoint.zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    let next = nextValue()
    value = CGPoint(x: value.x + next.x, y: value.y + next.y)
  }
}

struct CanvasRectKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

struct ViewPortRectKey: PreferenceKey {
  static var defaultValue: CGRect = .zero
  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}

struct CanvasView_Previews: PreviewProvider {
  static var previews: some View {
    let sampleSetStore = SampleSetStore(withMockResults: "Samples/SampleSetIndex.json")

    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: MockMusicEngine(),
      canvasStore: CanvasStore(sampleSetStore: sampleSetStore),
      sampleSetStore: sampleSetStore,
      canvasMessageStore: nil
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

extension CanvasViewModel {
  static func previewMock() -> CanvasViewModel {
    CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: nil),
      musicEngine: MockMusicEngine(),
      canvasStore: nil,
      sampleSetStore: nil,
      canvasMessageStore: nil
    )
  }
}


// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml

// UPDATED TODO - Nov 2025
// [DONE]- remove library view and related functionality
//   [DONE]- add way in pulldown menu to switch genres
//   [DONE]- fix tests to exercise adding / removing blocks
// [DONE]- add context menu for tapping on block
//   [DONE]- add selection state for block
//   [DONE]- delete loop
//   [DONE]- mute loop
//   - add support to custom name block
//   [DONE]- add extend loop to multiple bars (or shorten)
// - [DONE]add multi-bar support for loops
//   - [DONE]extended rectangle renderer
//   - [DONE]incorporate length into model
//   - [DONE]change block length on the fly in details view
//   - [DONE]**update block group positions when block length changes
//   - [DONE]update block details waveform view to show loop boundary
//   - [DONE]**implement loop offset
//   [DONE]- refactor increment / decrement settings to view model
//   - fix perf problems when incrementing / decrementing numBars
//   - visually disable increment / decriment buttons when they are beyond their limits
// - [DONE] **implement duplicate blocks
// - **implement volume on blocks
//   - hook up mute and gray out the block when it is muted
// - [DONE]**add animation for block after it is dropped till the next bar when playback starts
// - [DONE]**(add ability to import your own samples from documents folder
//   [DONE]- create documents folder
//   [DONE]- how to deal with tempo adjustment and loop length?
//   [DONE]- copy default files out to documents folder
//   [DONE]- download additional genres to documents folder
//   [DONE]- store songs in documents folder
// [DONE]- **figure out how to select a group and set group properties (mute etc...)
//   [DONE]- add some control pill that hangs out under groups
//   - add controls to this pill
//   [DONE]- allow the user to drag the pill to move it around
//   [DONE]- tapping should bring up a group details sheet
//   - group details operations (mute, solo?, volume ?)
//      - delete group
//      - volume
//      - duplicate group
//   - fix animation for dragging
// [DONE]- update tests for loading and saving to make sure all block and canvas state can be serialized properly
// - add the ability to connect block groups when dragging them next to each other
// [DONE]- update header UX
//   [DONE]- start stop transport controls
//   {DONE]- BPM setting
// - audit cleanup to make sure all subscriptions are cleaned up properly etc..
// - fix load song view grid layout to have proper spacing
//   - fix missing thumbnails icon
//   - make start / stop transport controls work better (maybe rewind to beginning?)


// MULTI-USER
// hook up shareplay so multiple users can edit a canvas at the same time
// [DONE]- add DTO for all objects
// [DONE]- hook up messages for actions
// [DONE]- setup robust testing framework w mocks
// [DONE]- do catchup action for when participants join
// [DONE]- do start / stop transport control messages
// [DONE]- do UI entry point
//   [DONE]- start shareplay when elligible button
//   [DONE]- leave shareplay session
//  - ability to update custom username

// ***Figure out how to layer on effects
// - maybe a painting model?
// - or some kind of mat you drag on
// - need to update UI w/ a tool bar to be able to add effects, loops, visuals


// AUv3
// make AUv3 plugin so you can record into loops from other audio apps

// Genre downloading
// - re-do download to download genre zip files from AWS and unzip


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

// [DONE] Refactor all views so they easily work with preview w/ mock data


// Capstone project requirements
// -- handle network errors gracefully (toast?)
// -- make app work in landscape and portrait mode
//    -- canvas view
//   [DONE]-- make library blocks reset location on rotation
//   [DONE]-- make library 1 row of blocks
//   [NA]-- make portrait mode work upside-down
//   [DONE]-- home view
//   [DONE]-- song list view
//   [DONE]-- download genres sheet
//   [DONE]-- rename song sheet
//   [DONE]-- place holder view
// -- make app work in light and dark mode
// -- [DONE] add SwiftUI animation somewhere
// -- [DONE] find a place to add tab navigation
// -- add UI tests

// Add more comprehensive tests (+ view model refactoring to make this easier)


// GB genre BPMs - electronica - 133.0 funk - 115.0

