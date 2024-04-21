//
//  ImageDetailsView.swift
//  ImageSearch
//
//  Created by Peter Rice on 3/18/24.
//

import SwiftUI

struct ImageDetailsView: View {
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
  }
}


struct ImageDetailsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ImageDetailsView(
        imageResult: PlexelImage(
          id: 1,
          width: 4000,
          height: 6000,
          url: "https://www.pexels.com/photo/woman-in-white-long-sleeved-top-and-skirt-standing-on-field-2880507/",
          photographer: "Deden Dicky Ramdhani",
          photographerUrl: "https://www.pexels.com/@drdeden88",
          title: "Woman in white long sleeved top and skirt standing on field",
          liked: false,
          sourceURLs: PlexelImageSourceURLs(
            original: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg",
            large2x: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=650&w=940",
            large: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&h=650&w=940",
            medium: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&h=350",
            small: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&h=130",
            portrait: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=1200&w=800",
            landscape: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&fit=crop&h=627&w=1200",
            tiny: "https://images.pexels.com/photos/2880507/pexels-photo-2880507.jpeg?auto=compress&cs=tinysrgb&dpr=1&fit=crop&h=200&w=280")))
    }
  }
}
