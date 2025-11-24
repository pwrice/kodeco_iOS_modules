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
  @State var showingBlockDetailsView = false
  @State var showingBlockGroupDetailsView = false
  @State var addBlockTapPosition: CGPoint?
  @State var showingSongListView = false

  var canvasBlocksView: some View {
    CanvasBlocksView(
      viewModel: viewModel,
      showingBlockDetailsView: $showingBlockDetailsView,
      showingBlockGroupDetailsView: $showingBlockGroupDetailsView)
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
    .onChange(of: showingBlockDetailsView) { _, newValue in
      if newValue == false {
        viewModel.unselectCurrentlySelectedBlock()
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
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

      ToolbarItem(placement: .principal) {
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

      ToolbarItem(placement: .navigationBarTrailing) {
        HStack {
          if viewModel.canvasMessageStore?.eligibleToStartSharing == true {
            Button {
              viewModel.startSharing()
            } label: {
              Image(systemName: "shareplay")
            }
          }

          if viewModel.canvasMessageStore?.sharePlaySessionActive == true {
            sharePlayMenuView
          }

          canvasMenuView
        }
      }
    }
    .sheet(isPresented: $showingRenameSongView, content: {
      RenameSongSheet(viewModel: viewModel, showingRenameSongView: $showingRenameSongView)
    })
    .sheet(isPresented: $showingDownloadGenresView) {
      if let sampleSetStore = viewModel.sampleSetStore {
        DownloadGenresSheet(
          viewModel: viewModel,
          store: sampleSetStore,
          showingDownloadGenresView: $showingDownloadGenresView)
      }
    }
    .sheet(isPresented: $showingSongListView) {
      SongListView(
        canvasStore: viewModel.canvasStore!,
        sampleSetStore: viewModel.sampleSetStore!,
        isPresented: $showingSongListView,
        onSelect: { saved in
          viewModel.loadSong(name: saved.name)
        }
      )
    }
    .sheet(isPresented: $showingLibraryPickerView) {
      LibraryPickerSheet(
        library: viewModel.canvasModel.library,
        addBlockTapPosition: addBlockTapPosition,
        viewModel: viewModel,
        showingLibraryPickerView: $showingLibraryPickerView)
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

  var canvasMenuView: some View {
    Menu {
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
        viewModel.reloadSong()
      }
      Menu {
        // List all local sample sets as selectable items
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

  var sharePlayMenuView: some View {
    Menu {
      if let sharePlayUsers = viewModel.sharePlayUsers {
        ForEach(sharePlayUsers, id: \.id) { sharePlayUser in
          // list share play users as disabled epople
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
        //        viewModel.sendCanvasModelSnapshot()
        // TODO - add this - so request a snapshot from the host
      }

      Button("Reset Session") {
        viewModel.resetSharePlaySession()
      }
    } label: {
      Image(systemName: "person.2.fill")
    }
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
  @Binding var showingBlockDetailsView: Bool
  @Binding var showingBlockGroupDetailsView: Bool

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?
  @GestureState private var groupDragStartLocation: CGPoint?

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

  func blockGroupDragGesture(blockGroup: BlockGroup) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($groupDragStartLocation) { _, startLocation, _ in
        // Called before onChanged
        startLocation = startLocation ?? (blockGroup.leftMostBlock?.location ?? .zero)
      }
      .onChanged { value in
        var newLocation = groupDragStartLocation ?? (blockGroup.leftMostBlock?.location ?? .zero)
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockGroupDragLocation(blockGroup: blockGroup, location: newLocation)
      }
      .onEnded { _ in
        _ = viewModel.dropBlockGroupOnCanvas(blockGroup: blockGroup)
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
          .simultaneousGesture(
            TapGesture()
              .onEnded { _ in
                viewModel.selectBlock(block: blockModel)
                showingBlockDetailsView = true
              }
          )
      }

      ForEach(viewModel.allBlockGroups, id: \.id) { group in
        if group.allBlocks.count >= 2, let left = group.leftMostBlock {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .overlay(
              Image(systemName: "slider.vertical.3")
                .foregroundColor(.gray)
            )
            .frame(width: 20, height: max(40, CGFloat(left.numBars) * (CanvasViewModel.blockSize + CanvasViewModel.blockSpacing)))
            .position(CGPoint(
              x: left.location.x - (CanvasViewModel.blockSize / 2) - CanvasViewModel.blockSpacing - 12,
              y: left.location.y
            ))
            .gesture(blockGroupDragGesture(blockGroup: group))
            .simultaneousGesture(
              TapGesture()
                .onEnded { _ in
                  viewModel.selectBlockGroup(group: group)
                  showingBlockGroupDetailsView = true
                }
            )
        }
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
// - update header UX
//   - start stop transport controls
//   - BPM setting
// - audit cleanup to make sure all subscriptions are cleaned up properly etc..

// MULTI-USER
// hook up shareplay so multiple users can edit a canvas at the same time
// [DONE]- add DTO for all objects
// [DONE]- hook up messages for actions
// [DONE]- setup robust testing framework w mocks
// - do catchup action for when participants join
// - do start / stop transport control messages
// - do UI entry point
//   - start shareplay when elligible button
//   - leave shareplay session

// Figure out how to layer on effects
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



