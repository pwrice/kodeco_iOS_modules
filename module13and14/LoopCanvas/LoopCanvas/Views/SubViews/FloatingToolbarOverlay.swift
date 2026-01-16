import SwiftUI

struct FloatingToolbarOverlay: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        VStack(spacing: 8) {
          if viewModel.selectedTool == .effects {
            effectPicker
          }
          toolPicker
        }
        Spacer()
      }
      .padding(.bottom, 24)
    }
  }

  var toolPicker: some View {
    HStack(spacing: 12) {
      toolButton(for: .loop)
      toolButton(for: .effects)
      toolButton(for: .visuals)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(
      .ultraThinMaterial,
      in: Capsule()
    )
    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Input Tools")
  }

  @ViewBuilder
  func toolButton(for tool: InputTool) -> some View {
    Button {
      viewModel.setInputTool(tool)
    } label: {
      HStack(spacing: 6) {
        Image(systemName: tool.systemImage)
          .imageScale(.medium)
        Text(tool.label)
          .font(.subheadline)
          .fontWeight(.semibold)
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(
        Group {
          if viewModel.selectedTool == tool {
            Capsule().fill(Color.accentColor.opacity(0.2))
          } else {
            Capsule().fill(Color.clear)
          }
        }
      )
    }
    .buttonStyle(.plain)
    .foregroundStyle(viewModel.selectedTool == tool ? Color.accentColor : Color.primary)
    .overlay(
      Capsule()
        .stroke(
          viewModel.selectedTool == tool ?
          Color.accentColor :
            Color.secondary.opacity(0.3), lineWidth: viewModel.selectedTool == tool ? 1.5 : 1)
    )
    .accessibilityLabel(tool.label)
    .accessibilityAddTraits(viewModel.selectedTool == tool ? .isSelected : [])
    .contentShape(Capsule())
  }

  var effectPicker: some View {
    HStack(spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(viewModel.availableEffects) { effect in
            Button {
              viewModel.setSelectedEffect(effect)
            } label: {
              HStack(spacing: 6) {
                Image(systemName: effect.systemImage)
                  .imageScale(.medium)
                Text(effect.label)
                  .font(.subheadline)
                  .fontWeight(.semibold)
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 8)
              .background(
                Group {
                  if viewModel.selectedEffect == effect {
                    Capsule().fill(Color.accentColor.opacity(0.2))
                  } else {
                    Capsule().fill(Color.clear)
                  }
                }
              )
              .overlay(
                Capsule()
                  .stroke(viewModel.selectedEffect == effect ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: viewModel.selectedEffect == effect ? 1.5 : 1)
              )
            }
            .buttonStyle(.plain)
            .foregroundStyle(viewModel.selectedEffect == effect ? Color.accentColor : Color.primary)
            .contentShape(Capsule())
          }
          ColorPicker("Stroke Color", selection: $viewModel.strokeColor, supportsOpacity: false)
            .labelsHidden()
            .frame(width: 36, height: 36)
            .background(
              Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .contentShape(Circle())
            .accessibilityLabel("Stroke Color")
        }
        .padding(.horizontal, 4)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(
      .ultraThinMaterial,
      in: Capsule()
    )
    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 6)
  }
}
