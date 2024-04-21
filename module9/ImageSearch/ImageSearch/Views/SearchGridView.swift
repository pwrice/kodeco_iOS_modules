//
//  SearchGrid.swift
//  ImageSearch
//
//  Created by Peter Rice on 2/28/24.
//

import SwiftUI

struct SearchGridView: View {
  @StateObject var viewModel = ImageSearchViewModel(imageStore: ImageSearchStore())

  var resultColumns: [GridItem] {
    [
      GridItem(.flexible(minimum: 150)),
      GridItem(.flexible(minimum: 150))
    ]
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        ZStack {
          LazyVGrid(columns: resultColumns) {
            ForEach(viewModel.imageResults, id: \.self) { imageResult in
              NavigationLink(value: imageResult) {
                ImageResultView(imageResult: imageResult)
                  .background(.red)
              }
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
        ImageDetailsView(imageResult: imageResult)
      }
      .searchable(
        text: $viewModel.searchQuery,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Search")
      .onSubmit(of: .search) {
        viewModel.searchSubmitted()
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
      .clipShape(RoundedRectangle(cornerRadius: 25))
      Text(imageResult.title)
        .lineLimit(1)
        .truncationMode(.tail)
      Spacer()
    }
    .frame(height: 150)
  }
}


struct SearchGridView_Previews: PreviewProvider {
  static var previews: some View {
    SearchGridView(
      viewModel: ImageSearchViewModel(
        imageStore: ImageSearchStore(
          withMockResults: "MockResponse", query: "cats")
      ))

    SearchGridView(
      viewModel: ImageSearchViewModel(
        imageStore: nil,
        searchQuery: "Cats",
        searchLoadingState: .loadingSearch)
      )
    }
}

// TODO
// [DONE] - setup account and API key on  https://www.pexels.com/
// [DONE]- integrate swiftlint into build phases
// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
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
// - implement background download on details view
// - hook up loading state on grid view
// - implement loading progress bar
// - visual polish
//  - fix rounded rect radius on results images
//  - get rid of red background
// - add next page button to get next page of results
// TODO - add test to show that JSON parser gracefully handles missing keys for fields we dont care about
