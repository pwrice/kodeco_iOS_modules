//
//  ContentView.swift
//  ImageSearch
//
//  Created by Peter Rice on 2/28/24.
//

import SwiftUI

struct ContentView: View {
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
// - setup account and API key on  https://www.pexels.com/
// - integrate swiftlint into build phases
// - API Key: 


// REmove API KEY and put in plist file
