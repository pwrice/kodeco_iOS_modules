import SwiftUI

struct ColorSlider: View {
  @Binding var color: Double
  let labelText: String
  let accentColor: Color
  
  var body: some View {
    VStack {
      Text(labelText)
        .foregroundColor(Color("TextColor"))
      HStack {
        Slider(value: $color, in: 0...Constants.colorRange)
          .accentColor(accentColor)
        Text("\(Int(color.rounded()))")
          .foregroundColor(Color("TextColor"))
      }
    }
  }
}

struct SetColorButton: View {
  @Binding var redColor: Double
  @Binding var greenColor: Double
  @Binding var blueColor: Double
  @Binding var previewColor: Color
  
  var body: some View {
    Button("Set Color") {
      previewColor = Color(red: redColor / Constants.colorRange, green: greenColor / Constants.colorRange, blue: blueColor / Constants.colorRange)
    }
    .padding(20)
    .background(Color("ButtonColor"))
    .overlay(
      RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
        .strokeBorder(Color("ButtonStroke"), lineWidth: Constants.strokeWidth)
    )
    .foregroundColor(Color("ButtonTextColor"))
    .cornerRadius(Constants.buttonCornerRadius)
    .bold()
  }
}
