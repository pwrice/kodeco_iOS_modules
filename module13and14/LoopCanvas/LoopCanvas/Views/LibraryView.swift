//
//  LibraryView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

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
        Task {
          // We need to wait a beat apparently for the UI to update when coming in from the navigation controller
          try await Task.sleep(for: .seconds(0.15))
          viewModel.canvasModel.library.libaryFrame = metrics.frame(in: .named("ViewportCoorindateSpace"))
          viewModel.libraryBlockLocationsUpdated()
        }
      }
    }
    )
  }
}

struct LibrarySlotView: View {
  @Binding var librarySlotLocations: [CGPoint]
  let index: Int

  var body: some View {
    ZStack {
      GeometryReader { metrics in
        RoundedRectangle(cornerRadius: 10)
          .foregroundColor(.gray)
          .onAppear {
            Task {
              // We need to wait a beat apparently for the UI to update when coming in from the navigation controller
              try await Task.sleep(for: .seconds(0.1))

              self.librarySlotLocations[index] = CGPoint(
                x: metrics.frame(in: .named("ViewportCoorindateSpace")).midX,
                y: metrics.frame(in: .named("ViewportCoorindateSpace")).midY
              )
            }
          }
      }
    }
    .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
  }
}
