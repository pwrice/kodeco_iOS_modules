//
//  DownloadGenresSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 9/21/24.
//

import SwiftUI

struct DownloadGenresSheet: View {
  let viewModel: CanvasViewModel
  @ObservedObject var store: SampleSetStore
  @Binding var showingDownloadGenresView: Bool
  @State private var showErrorToast = false

  var body: some View {
    NavigationView {
      VStack {
        if store.remoteSampleSetIndexLoadingState == .loading {
          ProgressView()
        } else if store.remoteSampleSetIndexLoadingState == .loaded {
          List(store.downloadableSampleSets) { sampleSet in
            SampleSetRowView(viewModel: viewModel, sampleSet: sampleSet)
          }
          .listStyle(.plain)
        } else if store.remoteSampleSetIndexLoadingState == .error {
          Text("Error connecting to server to load genres.")
            .padding()
          Button("Try Again") {
            store.loadRemoteSampleSetIndex()
          }
        }
      }
      .navigationBarTitle(Text("Download Genres"), displayMode: .inline)
      .navigationBarItems(
        trailing: Button(action: {
          showingDownloadGenresView = false
        }, label: {
          Text("Done")
        }))
      .onAppear {
        store.loadRemoteSampleSetIndex()
      }
      .onChange(of: store.errorDownloadingSampleSets) { _, newState in
        if newState {
          showErrorToast = true
        }
      }
      .toast(isPresented: $showErrorToast, message: "Failed to download genre. Please try again.")
    }
  }
}

struct SampleSetRowView: View {
  let viewModel: CanvasViewModel
  @ObservedObject var sampleSet: DownloadableSampleSet

  var body: some View {
    HStack {
      Text(sampleSet.remoteSampleSet.name)
        .bold()
      Spacer()
      if sampleSet.loadingState == .loaded
        && viewModel.selectedSampleSetName != sampleSet.remoteSampleSet.name {
        Button(action: {
          viewModel.removeLocalSampleSet(sampleSet)
        }, label: {
          Text("Remove Download")
        })
        .buttonStyle(.borderless)
      } else if sampleSet.loadingState == .notLoaded || sampleSet.loadingState == .error {
        Button(action: {
          viewModel.downloadRemoteSampleSet(sampleSet)
        }, label: {
          Text("Download")
        })
        .buttonStyle(.borderless)
      } else if sampleSet.loadingState == .loading {
        Text("Downloading \(Int(100 * sampleSet.downloadProgress))")
      }
    }
    .padding()
  }
}

struct DownloadGenresSheet_Previews: PreviewProvider {
  static var previews: some View {
    let sampleSetStore = SampleSetStore(withMockResults: "Samples/SampleSetIndex.json")
    let viewModel = CanvasViewModel(
      canvasModel: CanvasModel(sampleSetStore: sampleSetStore),
      musicEngine: MockMusicEngine(),
      canvasStore: CanvasStore(sampleSetStore: sampleSetStore),
      sampleSetStore: sampleSetStore
    )

    Group {
      // Portrait Preview
      DownloadGenresSheet(
        viewModel: viewModel,
        store: sampleSetStore,
        showingDownloadGenresView: .constant(true))
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Network Error (Remote SampleSets)
      DownloadGenresSheet(
        viewModel: viewModel,
        store: SampleSetStore(
          withMockResults: "Samples/SampleSetIndex.json",
          mockErrorState: .error),
        showingDownloadGenresView: .constant(true))
      .previewDisplayName("Network Error (Remote SampleSets)")
      .previewInterfaceOrientation(.portrait)

      // Network Error (Downloading SampleSets)
      DownloadGenresSheet(
        viewModel: viewModel,
        store: SampleSetStore(
          withMockResults: "Samples/SampleSetIndex.json",
          mockErrorDownloadingSampleSets: true),
        showingDownloadGenresView: .constant(true))
      .previewDisplayName("Network Error (Remote SampleSets)")
      .previewInterfaceOrientation(.portrait)


      // Portrait Dark Mode
      DownloadGenresSheet(
        viewModel: viewModel,
        store: sampleSetStore,
        showingDownloadGenresView: .constant(true))
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      DownloadGenresSheet(
        viewModel: viewModel,
        store: sampleSetStore,
        showingDownloadGenresView: .constant(true))
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
