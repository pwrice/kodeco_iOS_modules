//
//  ToastModifier.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/27/24.
//

import SwiftUI

struct ToastModifier: ViewModifier {
  @Binding var isPresented: Bool
  var message: String
  var duration: TimeInterval = 2.0

  func body(content: Content) -> some View {
    ZStack {
      content

      if isPresented {
        ToastView(message: message)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: isPresented)
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
              isPresented = false
            }
          }
        }
      }
    }
  }
}

struct ToastView: View {
  var message: String
  var body: some View {
    VStack {
      Spacer()
      Text(message)
        .font(.subheadline)
        .foregroundColor(Color("ErrorToastMessageColor"))
        .padding()
        .background(Color("ErrorToastBackgroundColor").opacity(0.8))
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.bottom, 50)
    }
  }
}

extension View {
  func toast(isPresented: Binding<Bool>, message: String, duration: TimeInterval = 2.0) -> some View {
    self.modifier(ToastModifier(isPresented: isPresented, message: message, duration: duration))
  }
}


struct ToastView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Portrait Preview
      ToastView(message: "Failed to load genres. Please try again.")
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      ToastView(message: "Failed to load genres. Please try again.")
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      ToastView(message: "Failed to load genres. Please try again.")
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
