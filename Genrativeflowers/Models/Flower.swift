//
//  Flower.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Foundation
import SwiftUI

/// Represents a single generative flower with all visual and animation properties
struct Flower: Identifiable {
  let id: UUID
  var position: CGPoint  // Current head position (calculated from stem end)

  // Generative properties
  let colorSeed: Double
  let petalCount: Int
  let petalRadius: CGFloat
  let stemCurvature: CGFloat
  let swaySpeed: Double
  let swayPhase: Double  // Randomized phase for wind variation
  var scale: CGFloat

  // Grounded physics properties
  var stemPath: [CGPoint]  // Points defining the stem (if drawn)
  let baseX: CGFloat  // Anchor point on the ground
  let height: CGFloat  // Height of the flower

  // Computed color based on palette
  func color(palette: ColorPalette) -> Color {
    return palette.randomColor(seed: colorSeed)
  }

  init(
    id: UUID = UUID(),
    position: CGPoint,  // Initial head position
    stemPath: [CGPoint] = [],  // Optional drawn stem
    colorSeed: Double? = nil,
    petalCount: Int? = nil,
    petalRadius: CGFloat? = nil,
    stemCurvature: CGFloat? = nil,
    swaySpeed: Double? = nil,
    swayPhase: Double? = nil,
    scale: CGFloat? = nil
  ) {
    self.id = id
    self.position = position
    self.stemPath = stemPath

    // If stem path provided, base is the first point, head is the last
    if let first = stemPath.first, let last = stemPath.last {
      self.baseX = first.x
      self.height = abs(first.y - last.y)
    } else {
      // Default vertical stem if spawned via tap
      self.baseX = position.x
      self.height = 300  // Default height
    }

    self.colorSeed = colorSeed ?? Double.random(in: 0...1)
    self.petalCount = petalCount ?? Int.random(in: 5...8)
    self.petalRadius = petalRadius ?? CGFloat.random(in: 20...40)
    self.stemCurvature = stemCurvature ?? CGFloat.random(in: 0.3...1.2)
    self.swaySpeed = swaySpeed ?? Double.random(in: 0.8...1.5)
    self.swayPhase = swayPhase ?? Double.random(in: 0...(.pi * 2))
    self.scale = scale ?? CGFloat.random(in: 0.7...1.3)
  }

  // Helper to calculate current head position based on wind
  func currentHeadPosition(time: TimeInterval, windStrength: Double, windDirection: Double)
    -> CGPoint
  {
    // Calculate sway from natural movement and wind
    let baseSway = sin(time * swaySpeed + swayPhase) * (10 * stemCurvature)
    let windEffect =
      sin(time * 2 + swayPhase) * (windStrength * 0.5) + (windStrength * cos(windDirection) * 0.3)

    let totalSway = baseSway + windEffect

    // For grounded flowers, position is fixed height, sway affects X
    if stemPath.isEmpty {
      // Simple vertical stem
      return CGPoint(
        x: baseX + totalSway,
        y: position.y
      )
    } else {
      // Drawn stem - head is last point plus sway
      return CGPoint(
        x: position.x + totalSway,
        y: position.y
      )
    }
  }

  // Helper for glow pulsation
  func glowPulse(at time: TimeInterval) -> Double {
    (sin(time * 1.2 + swayPhase) + 1) / 2
  }
}
