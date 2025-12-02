//
//  ControlPanel.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

/// Interactive control panel for adjusting garden parameters
struct ControlPanel: View {
  @Bindable var model: GardenModel
  let canvasSize: CGSize
  @State private var showClearConfirmation = false
  @State private var isExpanded = false

  var body: some View {
    VStack(alignment: .trailing, spacing: 0) {
      if isExpanded {
        // Expanded panel
        expandedPanel
          .transition(.move(edge: .trailing).combined(with: .opacity))
      } else {
        // Collapsed icon button
        collapsedButton
          .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
  }

  private var collapsedButton: some View {
    Button {
      isExpanded = true
    } label: {
      Image(systemName: "slider.horizontal.3")
        .font(.system(size: 24))
        .foregroundStyle(.white)
        .frame(width: 56, height: 56)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
  }

  private var expandedPanel: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with close button
      HStack {
        Text("Controls")
          .font(.headline)
          .foregroundStyle(.white)
        Spacer()
        Button {
          isExpanded = false
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 22))
            .foregroundStyle(.white.opacity(0.6))
        }
      }

      // Bloom Intensity
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Bloom")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.8))
          Spacer()
          Text(String(format: "%.1f", model.bloomIntensity))
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
        }
        Slider(value: $model.bloomIntensity, in: 0...1.6)
          .tint(.cyan)
      }

      // Chromatic Offset
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Chromatic")
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.8))
          Spacer()
          Text(String(format: "%.1f", model.chromaticOffset))
            .font(.caption)
            .foregroundStyle(.white.opacity(0.6))
        }
        Slider(value: $model.chromaticOffset, in: 0...8)
          .tint(.purple)
      }

      // Stars Toggle
      Toggle("Stars", isOn: $model.showStars)
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.8))
        .tint(.yellow)

      Divider()
        .background(.white.opacity(0.3))

      // Action Buttons
      VStack(spacing: 8) {
        Button {
          model.addRandomFlower(in: canvasSize)
        } label: {
          HStack {
            Image(systemName: "sparkles")
            Text("Add Random Flower")
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.cyan.opacity(0.3))
          .cornerRadius(8)
        }
        .foregroundStyle(.white)

        Button {
          showClearConfirmation = true
        } label: {
          HStack {
            Image(systemName: "trash")
            Text("Clear All")
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.red.opacity(0.3))
          .cornerRadius(8)
        }
        .foregroundStyle(.white)
      }

      // Flower Count
      Text("\(model.flowers.count) flowers")
        .font(.caption)
        .foregroundStyle(.white.opacity(0.5))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .padding(20)
    .frame(width: 280)
    .background(.ultraThinMaterial)
    .cornerRadius(16)
    .shadow(color: .black.opacity(0.3), radius: 10)
    .confirmationDialog(
      "Clear all flowers?",
      isPresented: $showClearConfirmation,
      titleVisibility: .visible
    ) {
      Button("Clear All", role: .destructive) {
        model.clearAll()
      }
      Button("Cancel", role: .cancel) {}
    }
  }
}
