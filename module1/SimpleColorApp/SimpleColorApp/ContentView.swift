//
//  ContentView.swift
//  SimpleColorApp
//
//  Created by Peter Rice on 12/2/23.
//

import SwiftUI

struct ContentView: View {
  
  @State private var redSliderValue: Double
  @State private var greenSliderValue: Double
  @State private var blueSliderValue: Double
  @State private var boxColor:Color
  
  init(red: Double = 0.7, green: Double = 0.7, blue: Double = 0.7) {
    self.redSliderValue = red
    self.greenSliderValue = green
    self.blueSliderValue = blue
    self.boxColor = Color(red: red, green: green, blue: blue)
  }
  
  var body: some View {
    VStack {
      Text("Color Picker")
        .font(.largeTitle)
      RoundedRectangle(cornerRadius: 0)
        .fill(boxColor)
      Text("Red")
      HStack {
        Slider(value: $redSliderValue)
        Text(String(Int((redSliderValue * 255.0).rounded())))
      }
      Text("Green")
      HStack {
        Slider(value: $greenSliderValue)
        Text(String(Int((greenSliderValue * 255.0).rounded())))
      }
      Text("Blue")
      HStack {
        Slider(value: $blueSliderValue)
        Text(String(Int((blueSliderValue * 255.0).rounded())))
      }
      Button("Set Color") {
        boxColor = Color(red: redSliderValue, green: greenSliderValue, blue: blueSliderValue)
      }
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
