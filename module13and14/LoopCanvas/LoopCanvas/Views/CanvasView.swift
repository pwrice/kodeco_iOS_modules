//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI

let blockSize: CGFloat = 70.0
let blockSpacing: CGFloat = 10.0

struct BlockModel: Identifiable {
  let id: Int
  let index: Int
  var location: CGPoint
  var isDragging: Bool
  let color: Color
    var visible = false
}


struct CanvasView: View {
  @GestureState private var fingerLocation: CGPoint?
  @GestureState private var dragStartLocation: CGPoint?

  @State private var blockModels = [
    BlockModel(
      id: 0,
      index: 0,
      location: CGPoint(x: 50, y: 50),
      isDragging: false,
      color: .pink),
    BlockModel(
      id: 1,
      index: 1,
      location: CGPoint(x: 50, y: 50),
      isDragging: false,
      color: .purple),
    BlockModel(
      id: 2,
      index: 2,
      location: CGPoint(x: 50, y: 50),
      isDragging: false,
      color: .indigo),
    BlockModel(
      id: 3,
      index: 3,
      location: CGPoint(x: 50, y: 50),
      isDragging: false,
      color: .yellow)
  ]

  @State private var librarySlotLocations: [CGPoint] = [
    CGPoint(x: 50, y: 150),
    CGPoint(x: 150, y: 150),
    CGPoint(x: 250, y: 150),
    CGPoint(x: 350, y: 150)
  ]

  var fingerDrag: some Gesture {
    DragGesture()
      .updating($fingerLocation) { value, fingerLocation, _ in
        fingerLocation = value.location
      }
  }

  func updateBlockLocationFromDragGuesture(blockIndex: Int, value: DragGesture.Value) {
  }

  var body: some View {
    ZStack {
      BackgroundView(librarySlotLocations: $librarySlotLocations)
      ForEach(blockModels) { blockModel in
        BlockView(model: blockModel)
          .gesture(
            DragGesture()
              .updating($dragStartLocation) { _, startLocation, _ in
                // Called before onChanged
                startLocation = startLocation ?? blockModels[blockModel.index].location
              }
              .onChanged { value in
                var newLocation = dragStartLocation ?? blockModels[blockModel.index].location
                newLocation.x += value.translation.width
                newLocation.y += value.translation.height
                blockModels[blockModel.index].location = newLocation
              }
              .onEnded { _ in
                detectBlockConnections(block: blockModel)
              }
              .simultaneously(with: fingerDrag)
          )
      }
      if let fingerLocation = fingerLocation {
        Circle()
          .stroke(Color.green, lineWidth: 2)
          .frame(width: 44, height: 44)
          .position(fingerLocation)
      }
    }
    .coordinateSpace(name: "CanvasViewCoorindateSpace")
    .onAppear {
      // Defer setting block location till layout pass updates librarySlotLocations
      Task {
        for (index, location) in librarySlotLocations.enumerated() {
          blockModels[index].location = location
          blockModels[index].visible = true
        }
      }
    }
  }

  func detectBlockConnections(block: BlockModel) {
    // Check all slots around all blocks to see if there is a connection
    for otherBlock in blockModels where otherBlock.id != block.id {
      // Find closest intersecting slot for otherBlock
      let slotLocations = [
        CGPoint( // top
          x: otherBlock.location.x,
          y: otherBlock.location.y - blockSpacing - blockSize),
        CGPoint( // right
          x: otherBlock.location.x + blockSpacing + blockSize,
          y: otherBlock.location.y),
        CGPoint( // bottom
          x: otherBlock.location.x,
          y: otherBlock.location.y + blockSpacing + blockSize),
        CGPoint( // left
          x: otherBlock.location.x - blockSpacing - blockSize,
          y: otherBlock.location.y)
      ]
      var intersectingSlot: CGPoint?
      var minDist: CGFloat = 100000000.0
      for slotLocation in slotLocations {
        let diffX = block.location.x - slotLocation.x
        let diffY = block.location.y - slotLocation.y
        let dist = diffX * diffX + diffY * diffY
        if abs(diffX) < blockSize && abs(diffY) < blockSize && dist < minDist {
          intersectingSlot = slotLocation
          minDist = dist
          break
        }
      }

      // make sure slot is not already occupied
      var availableSlot: CGPoint? = intersectingSlot
      for otherBlock in blockModels where otherBlock.id != block.id {
        if otherBlock.location == availableSlot {
          availableSlot = nil
        }
      }

      // if slot is available, snap block there
      if let availableSlot = availableSlot {
        blockModels[block.index].location = availableSlot
        break
      }
    }

    // regardless, add a new block to the open library slot
    for librarySlotLocation in librarySlotLocations {
      let blockInLibarySlot = blockModels.first { maybeBlock in
        maybeBlock.id != block.id && maybeBlock.location == librarySlotLocation
      }
      if blockInLibarySlot == nil {
        blockModels.append(
          BlockModel(
            id: blockModels.count,
            index: blockModels.count,
            location: librarySlotLocation,
            isDragging: false,
            color: block.color,
            visible: true
          ))
        break
      }
    }
  }
}

struct BlockView: View {
  let model: BlockModel

  var body: some View {
    RoundedRectangle(cornerRadius: 10)
      .foregroundColor(model.color)
      .frame(width: blockSize, height: blockSize)
      .position(model.location)
      .opacity(model.visible ? 1 : 0)
  }
}

struct BackgroundView: View {
  @Binding var librarySlotLocations: [CGPoint]

  var body: some View {
    VStack {
      HStack {
        Text("Loop Canvas")
        Spacer()
      }
      .padding()
      Spacer()
      LibraryView(librarySlotLocations: $librarySlotLocations)
    }
  }
}

struct LibraryView: View {
  @Binding var librarySlotLocations: [CGPoint]

  var body: some View {
    VStack {
      HStack {
        Text("Library")
        Spacer()
      }
      HStack(spacing: blockSpacing) {
        Spacer()
        LibrarySlotView(librarySlotLocations: $librarySlotLocations, index: 0)
        LibrarySlotView(librarySlotLocations: $librarySlotLocations, index: 1)
        LibrarySlotView(librarySlotLocations: $librarySlotLocations, index: 2)
        LibrarySlotView(librarySlotLocations: $librarySlotLocations, index: 3)
        Spacer()
      }
    }
    .padding()
    .background(Color.mint)
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
    .frame(width: blockSize, height: blockSize)
  }
}


struct CanvasView_Previews: PreviewProvider {
  static var previews: some View {
    CanvasView()
  }
}


// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml
