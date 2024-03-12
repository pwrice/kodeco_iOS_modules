//
//  ContentView.swift
//  ImageSearch
//
//  Created by Peter Rice on 2/28/24.
//

import SwiftUI

struct ContentView: View {
  @StateObject var imageSearchViewModel = ImageSearchViewModel(imageStore: ImageSearchStore())

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// TODO
// [DONE] - setup account and API key on  https://www.pexels.com/
// - integrate swiftlint into build phases
// [DONE] - REmove API KEY and put in plist file
// [DONE]- build out decodable model files based on JSON API
// [DONE]- implement model store
// [DONE]- setup model store tests
// [DONE]- implement auth headers
// - implement search view
// - implement view model
//  - figure out how to display search bar
//  - figure out how to do grid for results
// - implement details view
// - implement loading progress bar
