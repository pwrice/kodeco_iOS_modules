//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI


struct CanvasView: View {
  @StateObject var viewModel: CanvasViewModel

  var body: some View {
    ZStack {
      ScrollView([.horizontal, .vertical]) {
        ZStack {
          BackgroundDots()

          CanvasBlocksView(viewModel: viewModel)

          GeometryReader { proxy in
            let xOffset = proxy.frame(in: .named("CanvasCoordinateSpace")).minX
            let yOffset = proxy.frame(in: .named("CanvasCoordinateSpace")).minY
            // This prefernces method to calculate the scroll offset
            // seems a bit hacky. Is there a better way?
            Color.clear.preference(
              key: ViewOffsetKey.self,
              value: CGPoint(x: xOffset, y: yOffset))
          }
        }
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
      }
      .defaultScrollAnchor(.center)
      .coordinateSpace(name: "CanvasCoordinateSpace")
      .onPreferenceChange(ViewOffsetKey.self) {
        viewModel.canvasScrollOffset = $0
      }

      UIOverlayView(viewModel: viewModel)

      LibraryBlocksView(viewModel: viewModel)
    }
    .coordinateSpace(name: "ViewportCoorindateSpace")
    .onAppear {
      Task {
        viewModel.onViewAppear()
      }
    }
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGPoint
  static var defaultValue = CGPoint(x: CGFloat.zero, y: CGFloat.zero)
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
      ForEach(viewModel.allBlocks) { blockModel in
        BlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
      }
    }
  }
}

struct LibraryBlocksView: View {
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
    ZStack {
      ForEach(viewModel.libraryBlocks) { blockModel in
        BlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
      }
    }
  }
}

struct BlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    RoundedRectangle(cornerRadius: 10)
      .foregroundColor(model.color)
      .frame(
        width: CanvasViewModel.blockSize,
        height: CanvasViewModel.blockSize)
      .position(model.location)
      .opacity(model.visible ? 1 : 0)
      .overlay {
        Image(systemName: model.icon)
          .position(model.location)
          .foregroundColor(.white)
      }
  }
}

struct BackgroundDots: View {
  var body: some View {
    ZStack { // Background dots
      let dotSpacing = CanvasViewModel.blockSize + CanvasViewModel.blockSpacing
      let numCols = Int(CanvasViewModel.canvasWidth / dotSpacing)
      let numRows = Int(CanvasViewModel.canvasHeight / dotSpacing)
      ForEach(0..<numCols, id: \.self) { hInd in
        ForEach(0..<numRows, id: \.self) { vInd in
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

struct UIOverlayView: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    VStack {
      HStack {
        Text("Loop Canvas")
        Spacer()
      }
      .padding()
      Spacer()
      LibraryView(viewModel: viewModel)
    }
  }
}

struct LibraryView: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    VStack {
      HStack {
        Text("Loops")
        Picker(
          "Category",
          selection: $viewModel.selectedCategoryName) {
            ForEach(
              viewModel.canvasModel.library.categories.map { $0.name },
              id: \.self) {
                Text($0)
            }
        }.pickerStyle(.menu)
          .onChange(
            of: viewModel.selectedCategoryName,
            initial: false) { _, _ in
              viewModel.selectLoopCategory(
                categoryName: viewModel.selectedCategoryName)
          }
        Spacer()
      }
      HStack(spacing: CanvasViewModel.blockSpacing) {
        Spacer()
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 0)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 1)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 2)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 3)
        Spacer()
      }
      HStack(spacing: CanvasViewModel.blockSpacing) {
        Spacer()
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 4)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 5)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 6)
        LibrarySlotView(librarySlotLocations: $viewModel.canvasModel.library.librarySlotLocations, index: 7)
        Spacer()
      }
    }
    .padding()
    .background(Color.mint)
    .overlay(GeometryReader { metrics in
      ZStack {
        Spacer()
      }
      .onAppear {
        viewModel.canvasModel.library.libaryFrame = metrics.frame(in: .named("ViewportCoorindateSpace"))
      }
    }
    )
  }
}

struct LibrarySlotView: View {
  @Binding var librarySlotLocations: [CGPoint]
  let index: Int

  var body: some View {
    GeometryReader { metrics in
      RoundedRectangle(cornerRadius: 10)
        .foregroundColor(.gray)
        .onAppear {
          self.librarySlotLocations[index] = CGPoint(
            x: metrics.frame(in: .named("ViewportCoorindateSpace")).midX,
            y: metrics.frame(in: .named("ViewportCoorindateSpace")).midY
          )
        }
    }
    .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
  }
}


struct CanvasView_Previews: PreviewProvider {
  static var previews: some View {
    CanvasView(
      viewModel: CanvasViewModel(
        canvasModel: CanvasModel(),
        musicEngine: MockMusicEngine()
      ))
  }
}


// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml


// Library TODO
// [DONE] Add symbols to blocks to differentiate w/in a category
// [DONE] Add picker to library to allow switching between categories
// [DONE] - add picker UI
// [DONE] - swap out blocks when picker choice is made
// [DONE] - add dot grid background to canvas (so it is easier to see scrolling)
// [DONE] Refactor views into smaller subviews

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
