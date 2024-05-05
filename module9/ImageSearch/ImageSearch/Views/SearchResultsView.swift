//
//  SearchGrid.swift
//  ImageSearch
//
//  Created by Peter Rice on 2/28/24.
//

import SwiftUI

struct SearchResultsView: View {
  @StateObject var viewModel = ImageSearchViewModel(imageStore: ImageSearchStore())

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          ResultsGridView(viewModel: viewModel)
          if viewModel.showMoreImagesButton {
            Button("More Images") {
              viewModel.moreImagesTapped()
            }
          }
          if viewModel.searchLoadingState == .loadingSearch {
            ProgressView()
          }
        }
      }
      .padding()
      .navigationTitle(Text("Plexel Images"))
      .navigationDestination(for: PlexelImage.self) { imageResult in
        ImageDetailsView(viewModel: viewModel, imageResult: imageResult)
      }
      .searchable(
        text: $viewModel.searchQuery,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search")
      .onSubmit(of: .search) {
        viewModel.searchInputSubmitted()
      }
    }
  }
}

struct ResultsGridView: View {
  @ObservedObject var viewModel: ImageSearchViewModel

  @Environment(\.isSearching) var isSearching

  var resultColumns: [GridItem] {
    [
      GridItem(.flexible(minimum: 150)),
      GridItem(.flexible(minimum: 150))
    ]
  }

  var body: some View {
    LazyVGrid(columns: resultColumns) {
      ForEach(viewModel.imageResults, id: \.self) { imageResult in
        NavigationLink(value: imageResult) {
          ImageResultView(imageResult: imageResult)
        }
      }
    }
    .onChange(of: isSearching) {
      if !isSearching {
        viewModel.clearSearch()
      }
    }
  }
}

struct ImageResultView: View {
  let imageResult: PlexelImage

  var body: some View {
    VStack {
      AsyncImage(
        url: URL(string: imageResult.sourceURLs.tiny)) { phase in
          switch phase {
          case .failure:
            Image(systemName: "photo")
              .font(.largeTitle)
          case .success(let image):
            image
              .resizable()
          default:
            ProgressView()
          }
      }
      .frame(width: 140, height: 100)
      Text(imageResult.title)
        .lineLimit(1)
        .truncationMode(.tail)
      Spacer()
    }
    .frame(height: 150)
  }
}


struct SearchResultsView_Previews: PreviewProvider {
  static var previews: some View {
    SearchResultsView(
      viewModel: ImageSearchViewModel(
        imageStore: ImageSearchStore(
          withMockResults: "MockResponse", query: "cats")
      ))

    SearchResultsView(
      viewModel: ImageSearchViewModel(
        imageStore: nil,
        searchQuery: "Cats",
        searchLoadingState: .loadingSearch)
      )
    }
}

// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml

// TODO
// [DONE] - setup account and API key on  https://www.pexels.com/
// [DONE]- integrate swiftlint into build phases
// [DONE] - REmove API KEY and put in plist file
// [DONE]- build out decodable model files based on JSON API
// [DONE]- implement model store
// [DONE]- setup model store tests
// [DONE]- implement auth headers
// [DONE]- implement way for previews to load mock data
// [DONE]- implement basic search results view
// [DONE]- implement fix grid layout and spacing
// [DONE]- implement search bar and button
// [DONE]- hook up search input
//  [DONE]- tapping enter should do trigger the search
// [DONE]- test against live API
// [DONE]- hook up loading indicator on search grid
// [DONE]- implement background download in image store
// [DONE]- trigger background download when navigatng to details screen
// [DONE]- display progress for downloads
// [DONE]- add next page button to get next page of results
// [DONE] - cancel in progress download when navigating to new details screen
