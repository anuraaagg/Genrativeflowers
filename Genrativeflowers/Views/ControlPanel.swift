//
//  ControlPanel.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

struct ControlPanel: View {
  @ObservedObject var appState: AppState
  @State private var showInstructions = false

  var body: some View {
    VStack(spacing: 20) {
      // Header
      Text("Control Centre")
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)

      // 1. Visual Settings
      VStack(spacing: 16) {
        Text("Visuals")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.gray)
          .frame(maxWidth: .infinity, alignment: .leading)

        ControlSlider(
          label: "Bloom",
          value: $appState.bloomIntensity,
          range: 0.2...3.0,
          step: 0.1,
          tooltip: "petal size & spread"
        )

        ControlSlider(
          label: "Chromatic",
          value: $appState.chromaticOffset,
          range: 0.0...10.0,
          step: 0.1,
          tooltip: "color glow intensity"
        )
      }

      // 2. Physics & Environment
      VStack(spacing: 16) {
        Text("Environment")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.gray)
          .frame(maxWidth: .infinity, alignment: .leading)

        ControlSlider(
          label: "Wind Strength",
          value: $appState.wind.strength,
          range: 0.0...50.0,
          step: 1.0,
          tooltip: "breeze strength"
        )

        HStack(spacing: 30) {
          Toggle("Stars", isOn: $appState.showStars)
          Toggle("Gyro", isOn: $appState.gyroWindEnabled)
          Toggle("Parallax", isOn: $appState.parallaxEnabled)
        }
        .labelsHidden()
        .toggleStyle(SwitchToggleStyle(tint: .blue))
        .overlay(
          HStack(spacing: 30) {
            Text("Stars").font(.caption)
            Text("Gyro").font(.caption)
            Text("Parallax").font(.caption)
          }
          .offset(y: 24)
        )
        .padding(.bottom, 10)
      }

      // Instructions (Bottom)
      Text("tap to spawn • drag to move • hold to grow")
        .font(.caption2)
        .foregroundStyle(.gray.opacity(0.6))
        .multilineTextAlignment(.center)
        .padding(.top, 12)
    }
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 20)
  }
}

struct ControlSlider: View {
  let label: String
  @Binding var value: Double
  let range: ClosedRange<Double>
  let step: Double
  let tooltip: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(label)
          .font(.caption)
          .foregroundColor(.black)
        Spacer()
        Text(String(format: "%.1f", value))
          .font(.caption)
          .monospacedDigit()
          .foregroundColor(.black)
      }
      Slider(value: $value, in: range, step: step)
      Text(tooltip)
        .font(.caption2)
        .foregroundStyle(.gray)
    }
  }
}

struct ToggleOption: View {
  let icon: String
  let label: String
  @Binding var isOn: Bool
  let accessibilityHint: String

  var body: some View {
    Button {
      isOn.toggle()
      HapticManager.shared.selectionChanged()
    } label: {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(isOn ? .cyan : .white.opacity(0.4))
          .frame(width: 44, height: 44)
          .background(
            Circle()
              .fill(isOn ? .cyan.opacity(0.2) : .white.opacity(0.1))
          )

        Text(label)
          .font(.system(size: 11, weight: .medium))
          .foregroundColor(isOn ? .white : .white.opacity(0.6))
      }
      .frame(maxWidth: .infinity)
    }
    .accessibilityLabel("\(label) \(isOn ? "enabled" : "disabled")")
    .accessibilityHint(accessibilityHint)
    .accessibilityAddTraits(.isButton)
  }
}

struct InstructionRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 14))
        .foregroundColor(.cyan.opacity(0.8))
        .frame(width: 20)
      Text(text)
        .font(.system(size: 13))
        .foregroundColor(.white.opacity(0.8))
    }
  }
}
