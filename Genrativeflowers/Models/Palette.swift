//
//  Palette.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

/// Defines the available color theory palettes for the garden
enum ColorPalette: String, CaseIterable, Identifiable {
  case pastel = "Pastel"
  case sakura = "Sakura"
  case neon = "Neon"
  case monochrome = "Monochrome"
  case sunset = "Sunset"

  var id: String { rawValue }

  /// Returns a random color from the palette
  func randomColor(seed: Double) -> Color {
    switch self {
    case .pastel:
      return Color(hue: seed, saturation: 0.4, brightness: 0.9)
    case .sakura:
      // Pink/White/Red hues
      let hue = 0.9 + (seed * 0.2)  // 0.9 to 1.1 (wrapping around 1.0)
      let wrappedHue = hue > 1.0 ? hue - 1.0 : hue
      return Color(hue: wrappedHue, saturation: 0.3 + (seed * 0.4), brightness: 0.95)
    case .neon:
      return Color(hue: seed, saturation: 0.8, brightness: 1.0)
    case .monochrome:
      return Color(white: 0.2 + (seed * 0.8))
    case .sunset:
      // Orange/Red/Purple/Yellow
      // Hues roughly 0.0 (red) to 0.16 (yellow) and 0.8 (purple)
      let variant = Int(seed * 4)
      switch variant {
      case 0: return Color(hue: 0.05, saturation: 0.8, brightness: 0.9)  // Orange
      case 1: return Color(hue: 0.12, saturation: 0.7, brightness: 1.0)  // Yellow
      case 2: return Color(hue: 0.95, saturation: 0.8, brightness: 0.8)  // Red-Pink
      default: return Color(hue: 0.8, saturation: 0.6, brightness: 0.7)  // Purple
      }
    }
  }

  /// Returns the next palette in the cycle
  var next: ColorPalette {
    let all = Self.allCases
    let index = all.firstIndex(of: self) ?? 0
    return all[(index + 1) % all.count]
  }
}
