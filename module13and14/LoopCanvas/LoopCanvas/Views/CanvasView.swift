//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI


struct CanvasView: View {
  @StateObject var viewModel: CanvasViewModel
  @GestureState private var fingerLocation: CGPoint?

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?

  var fingerDragGesture: some Gesture {
    DragGesture()
      .updating($fingerLocation) { value, fingerLocation, _ in
        fingerLocation = value.location
      }
  }

  func blockDragGesture(block: Block) -> some Gesture {
    DragGesture()
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
        viewModel.dropBlockOnCanvas(block: block)
      }
  }

  var body: some View {
    // Trying to figure out how to scroll the canvas
    //    ScrollView([.horizontal, .vertical]) {
    ZStack {
      BackgroundView(viewModel: viewModel)
      ZStack {
        ForEach(viewModel.allBlocks) { blockModel in
          BlockView(model: blockModel)
            .gesture(
              blockDragGesture(block: blockModel)
                .simultaneously(with: fingerDragGesture)
            )
        }
      }
      if let fingerLocation = fingerLocation {
        Circle()
          .stroke(Color.green, lineWidth: 2)
          .frame(width: 44, height: 44)
          .position(fingerLocation)
      }
    }
    //      .frame(width: 1000, height: 1000)
    .coordinateSpace(name: "CanvasViewCoorindateSpace")
    .onAppear {
      Task {
        viewModel.onViewAppear()
      }
    }
    //    }

  }
}

struct BlockView: View {
  @ObservedObject var model: Block

  var body: some View {
    RoundedRectangle(cornerRadius: 10)
      .foregroundColor(model.color)
      .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
      .position(model.location)
      .opacity(model.visible ? 1 : 0)
  }
}

struct BackgroundView: View {
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
        Text("Library")
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
    }
    .padding()
    .background(Color.mint)
    .overlay(GeometryReader { metrics in
      ZStack {
        Spacer()
      }
      .onAppear {
        viewModel.canvasModel.library.libaryFrame = metrics.frame(in: .named("CanvasViewCoorindateSpace"))
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
            x: metrics.frame(in: .named("CanvasViewCoorindateSpace")).midX,
            y: metrics.frame(in: .named("CanvasViewCoorindateSpace")).midY
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
