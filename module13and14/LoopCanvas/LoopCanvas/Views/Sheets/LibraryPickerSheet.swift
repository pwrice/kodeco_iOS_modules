//
//  LibraryPickerSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 11/7/25.
//
//

import SwiftUI

private enum Style {
  // General layout
  static let stackSpacing: CGFloat = 0

  // Pills / Tabs
  static let pillsHorizontalPadding: CGFloat = 16
  static let pillsVerticalPadding: CGFloat = 8
  static let pillsHStackSpacing: CGFloat = 12
  static let pillTextHorizontalPadding: CGFloat = 16
  static let pillTextVerticalPadding: CGFloat = 10

  // Blocks list
  static let blocksVStackSpacing: CGFloat = 12
  static let blocksVerticalPadding: CGFloat = 12

  // Block row
  static let blockRowHorizontalPadding: CGFloat = 16
  static let blockRowContentPadding: CGFloat = 16
  static let blockRowCornerRadius: CGFloat = 18
  static let blockRowStrokeWidth: CGFloat = 1
  static let blockPreviewSize: CGFloat = 64
  static let blockRowContentSpacing: CGFloat = 12

  // Typography
  static let blockTitleLineLimit: Int = 2

  // Colors
  static let pillSelectedForegroundColor: Color = .white
  static let pillUnselectedForegroundColor: Color = .primary
  static let pillSelectedBackgroundColor: Color = .accentColor
  static let pillUnselectedBackgroundColor = Color(.systemGray6)
  static let blockRowFillColor = Color(.secondarySystemBackground)
  static let blockRowStrokeColor = Color(.quaternaryLabel)
}

struct LibraryPickerSheet: View {
  @ObservedObject var library: Library
  var addBlockTapPosition: CGPoint?
  var viewModel: CanvasViewModel
  @Binding var showingLibraryPickerView: Bool
  @State private var selectedCategoryIndex: Int = 0

  var body: some View {
    NavigationView {
      VStack(spacing: Style.stackSpacing) {
        // Pills / Tabs row
        CategoryPillsView(library: library, selectedCategoryIndex: $selectedCategoryIndex)

        Divider()

        // Blocks list for selected category
        ScrollView {
          LazyVStack(spacing: Style.blocksVStackSpacing) {
            let categories = library.categories
            if categories.indices.contains(selectedCategoryIndex) {
              let category = categories[selectedCategoryIndex]
              ForEach(category.blocks) { blockModel in
                LibraryBlockRow(
                  blockModel: blockModel,
                  addBlockTapPosition: addBlockTapPosition,
                  viewModel: viewModel,
                  showingLibraryPickerView: $showingLibraryPickerView
                )
              }
            } else {
              // Fallback if no categories available
              Text("No categories available")
                .foregroundColor(.secondary)
                .padding()
            }
          }
          .padding(.vertical, Style.blocksVerticalPadding)
        }
      }
      .navigationBarTitle(Text("Add Block"), displayMode: .inline)
      .navigationBarItems(
        trailing: Button("Done") {
          showingLibraryPickerView = false
        }
      )
    }
  }
}

struct CategoryPillsView: View {
  @ObservedObject var library: Library
  @Binding var selectedCategoryIndex: Int

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: Style.pillsHStackSpacing) {
        ForEach(library.categories.indices, id: \.self) { index in
          let isSelected = (index == selectedCategoryIndex)
          let category = library.categories[index]
          Button(
            action: {
              selectedCategoryIndex = index
            },
            label: {
              Text(category.name)
                .font(.headline)
                .foregroundColor(isSelected ?
                  Style.pillSelectedForegroundColor :
                    Style.pillUnselectedForegroundColor)
                .padding(.horizontal, Style.pillTextHorizontalPadding)
                .padding(.vertical, Style.pillTextVerticalPadding)
                .background(
                  Capsule()
                    .fill(isSelected ?
                      Style.pillSelectedBackgroundColor :
                        Style.pillUnselectedBackgroundColor)
                )
            }
          )
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, Style.pillsHorizontalPadding)
      .padding(.vertical, Style.pillsVerticalPadding)
    }
  }
}

struct LibraryPickerSheet_Previews: PreviewProvider {
  static var previews: some View {
    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(
        sampleSetStore: nil),
      musicEngine: MockMusicEngine(),
      canvasStore: nil,
      sampleSetStore: nil
    )


    Group {
      // Portrait Preview
      LibraryPickerSheet(
        library: .preview(),
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      LibraryPickerSheet(
        library: .preview(),
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      LibraryPickerSheet(
        library: .preview(),
        viewModel: viewModel,
        showingLibraryPickerView: .constant(true))
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}

struct LibraryBlockRow: View {
  let blockModel: Block
  var addBlockTapPosition: CGPoint?
  var viewModel: CanvasViewModel
  @Binding var showingLibraryPickerView: Bool

  var body: some View {
    HStack(alignment: .center, spacing: Style.blockRowContentSpacing) {
      PreviewBlockView(model: blockModel)
        .frame(width: Style.blockPreviewSize, height: Style.blockPreviewSize)
      Text(blockModel.name)
        .font(.title3.weight(.semibold))
        .lineLimit(Style.blockTitleLineLimit)
        .multilineTextAlignment(.leading)
      Spacer(minLength: Style.stackSpacing)
    }
    .padding(Style.blockRowContentPadding)
    .background(
      RoundedRectangle(cornerRadius: Style.blockRowCornerRadius, style: .continuous)
        .fill(Style.blockRowFillColor)
    )
    .overlay(
      RoundedRectangle(cornerRadius: Style.blockRowCornerRadius, style: .continuous)
        .stroke(Style.blockRowStrokeColor, lineWidth: Style.blockRowStrokeWidth)
    )
    .padding(.horizontal, Style.blockRowHorizontalPadding)
    .onTapGesture {
      if let addBlockTapPosition = addBlockTapPosition {
        _ = viewModel.addBlockToCanvasOnGrid(
          block: blockModel.instantiateCopyWith(
            location: addBlockTapPosition,
            isLibraryBlock: false))
      }
      showingLibraryPickerView = false
    }
  }
}

#Preview("LibraryBlockRow Preview") {
  // Minimal environment for the row
  let viewModel = CanvasViewModel(
    canvasModel: CanvasModel(sampleSetStore: nil),
    musicEngine: MockMusicEngine(),
    canvasStore: nil,
    sampleSetStore: nil
  )

  // Create a simple Block for preview purposes
  let block = Block.preview()

  LibraryBlockRow(
    blockModel: block,
    addBlockTapPosition: CGPoint(x: 100, y: 100),
    viewModel: viewModel,
    showingLibraryPickerView: .constant(true)
  )
}

extension Block {
  static func preview(name: String = "Preview Block") -> Block {
    Block(
      id: getNextBlockId(),
      location: CGPoint(x: 200, y: 200),
      color: .pink,
      icon: "circle",
      loopURL: URL(fileURLWithPath: "Samples/Dub/Horns/horns-5.wav", relativeTo: Bundle.main.bundleURL),
      relativePath: "Samples/Dub/Horns/horns-5.wav"
    )
  }
}

extension Library {
  static func preview() -> Library {
    // Create a few sample categories with a few blocks each.
    let categoryNames = ["Drums", "Bass", "Horns"]

    let categories: [Category] = categoryNames.enumerated().map { catIndex, name in
      let blocks: [Block] = (1...4).map { idx in
        let block = Block(
          id: Block.getNextBlockId(),
          location: CGPoint(x: 100 + idx * 20, y: 150 + idx * 20),
          color: .pink,
          icon: "circle",
          loopURL: URL(
            fileURLWithPath: "Samples/\(name)/\(name.lowercased())-\(idx).wav",
            relativeTo: Bundle.main.bundleURL),
          relativePath: "Samples/\(name)/\(name.lowercased())-\(idx).wav"
        )
        return block
      }
      return Category(id: catIndex, name: name, color: .pink, blocks: blocks)
    }

    let sampleSetStore = SampleSetStore(withMockResults: "Samples/SampleSetIndex.json")
    return Library(categories: categories, sampleSetStore: sampleSetStore)
  }
}
