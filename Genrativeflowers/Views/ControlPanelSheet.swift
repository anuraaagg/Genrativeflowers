//
//  ControlPanelSheet.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 03/12/25.
//

import SwiftUI

/// Popup sheet for garden controls
struct ControlPanelSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Bindable var model: GardenModel
  let canvasSize: CGSize

  var body: some View {
    NavigationStack {
      Form {
        Section("Appearance") {
          HStack {
            Text("Bloom")
            Spacer()
            Slider(value: $model.chromaticOffset, in: 0...20)
              .frame(width: 200)
          }

          Toggle("Show Stars", isOn: $model.showStars)
        }

        Section("Wind") {
          HStack {
            Text("Strength")
            Spacer()
            Slider(value: $model.windStrength, in: 0...100)
              .frame(width: 200)
          }

          Toggle("Gyro Control", isOn: $model.isGyroWindEnabled)
        }

        Section("Colors") {
          Picker("Palette", selection: $model.currentPalette) {
            ForEach(ColorPalette.allCases, id: \.self) { palette in
              Text(palette.rawValue.capitalized)
            }
          }
        }

        Section("Actions") {
          Button("Add Random Flower") {
            model.addRandomFlower(in: canvasSize)
            HapticManager.shared.light()
          }

          Button("Clear All", role: .destructive) {
            model.flowers.removeAll()
            HapticManager.shared.heavy()
          }
        }
      }
      .navigationTitle("Garden Controls")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
  }
}
