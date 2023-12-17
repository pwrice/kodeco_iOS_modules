import SwiftUI

struct ContentView: View {
  @Environment(\.verticalSizeClass) var verticalSizeClass
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  @State private var alertIsVisible: Bool = false
  @State private var redColor: Double = Constants.defaultRedColor
  @State private var greenColor: Double = Constants.defaultGreenColor
  @State private var blueColor: Double = Constants.defaultBlueColor

  // When the app first runs, the default for previewColor shows up as white and not these values. Why?
  @State private var previewColor: Color =  Color(red: Constants.defaultRedColor, green: Constants.defaultGreenColor, blue: Constants.defaultBlueColor)
  
  var body: some View {
    
    ZStack {
      // The size class vars are not getting set and evaluating this if-statement. Why?
      if verticalSizeClass == .compact && horizontalSizeClass == .regular {
        // Handle landscape
        HStack(spacing: 20) {
          ColorPreviewView(previewColor: $previewColor)
          ColorSlidersView(redColor: $redColor, greenColor: $greenColor, blueColor: $blueColor, previewColor: $previewColor)
        }
      } else {
        // Default to portriat layout
        VStack(spacing: 20) {
          ColorPreviewView(previewColor: $previewColor)
          ColorSlidersView(redColor: $redColor, greenColor: $greenColor, blueColor: $blueColor, previewColor: $previewColor)
        }
      }
    }
    .padding(20)
    .background(Color("BackgroundColor"))

  }
}

struct ColorPreviewView: View {
  @Binding var previewColor: Color
                                                    
  var body: some View {
    VStack {
      Text("Color Picker")
        .font(.largeTitle)
        .fontWeight(.semibold)
        .foregroundColor(Color("TextColor"))
      
      Rectangle()
        .strokeBorder(Color("PreveiwRectStrokeColor"), lineWidth: Constants.preveiwRectStrokeWidth)
        .background(previewColor)
    }
  }
}

struct ColorSlidersView: View {
  @Binding var redColor: Double
  @Binding var greenColor: Double
  @Binding var blueColor: Double
  @Binding var previewColor: Color

  var body: some View {
    VStack {
      ColorSlider(color: $redColor, labelText: "Red", accentColor: .red)
      ColorSlider(color: $greenColor, labelText: "Green", accentColor: .green)
      ColorSlider(color: $blueColor, labelText: "Blue", accentColor: .blue)
      SetColorButton(redColor: $redColor, greenColor: $greenColor, blueColor: $blueColor, foregroundColor: $previewColor)
    }
  }
}


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
  @Binding var foregroundColor: Color
  
  var body: some View {
    Button("Set Color") {
      foregroundColor = Color(red: redColor / Constants.colorRange, green: greenColor / Constants.colorRange, blue: blueColor / Constants.colorRange)
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

enum Constants {
  public static let strokeWidth: CGFloat = 2.0
  public static let buttonCornerRadius: CGFloat = 18.0
  public static let preveiwRectStrokeWidth: CGFloat = 8.0
  
  public static let defaultRedColor: Double = 243.0
  public static let defaultGreenColor: Double = 109.0
  public static let defaultBlueColor: Double = 66.0
  
  public static let colorRange: Double = 255

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
    ContentView()
      .preferredColorScheme(.dark)
    ContentView()
      .previewInterfaceOrientation(.landscapeRight)
  }
}





/*
 Project TODO
 
 [DONE]- Add stroke with correct color around color rectangle
 [DONE]- Add treatment to SetColor Button
 [DONE]- app background color
 [DONE] - adjust content view padding to include background color
 [DONE]- stroke
 [DONE]- rounded corners
 [DONE]- add color sets and dark variants for colors
 [DONE]  - background color
 [DONE]  - text color
 [DONE]- add preview variants for light/dark
 [DONE]- extract views
 [DONE]  - button view
 [DONE]  - slider view
 [DONE]- consolidate magic numbers into constants
 [DONE]- make slider bar colors red/green/blue
 [SORTOF]- implement landscape layout
 [DONE]- fine-tune padding everywhere
 [DONE]- add preview variants for landscape
 */





