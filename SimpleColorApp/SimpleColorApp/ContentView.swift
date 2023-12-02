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
  
  init() {
    let defaultRed = 200.0
    let defaultGreen = 100.0
    let defaultBlue = 240.0
    
    self.redSliderValue = defaultRed
    self.greenSliderValue = defaultGreen
    self.blueSliderValue = defaultBlue
    self.boxColor = ContentView.calculateBoxColor(red: defaultRed, green: defaultGreen, blue: defaultBlue)
  }
  
  var body: some View {
    VStack {
      Text("Color Picker")
        .font(.largeTitle)
      RoundedRectangle(cornerRadius: 0)
        .fill(boxColor)
      Text("Red")
      HStack {
        Slider(value: $redSliderValue, in: 1.0...255.0)
        Text(String(Int(redSliderValue.rounded())))
      }
      Text("Green")
      HStack {
        Slider(value: $greenSliderValue, in: 1.0...255.0)
        Text(String(Int(greenSliderValue.rounded())))
      }
      Text("Blue")
      HStack {
        Slider(value: $blueSliderValue, in: 1.0...255.0)
        Text(String(Int(blueSliderValue.rounded())))
      }
      Button("Set Color") {
        boxColor = ContentView.calculateBoxColor(red: redSliderValue, green: greenSliderValue, blue: blueSliderValue)
      }
    }
    .padding()
  }
  
  private static func calculateBoxColor(red: Double, green: Double, blue: Double) -> Color {
    Color(red: red/255.0, green: green/255.0, blue: blue/255.0)
  }
}

#Preview {
  ContentView()
}
