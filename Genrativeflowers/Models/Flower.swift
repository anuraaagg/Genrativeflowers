//
//  Flower.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

struct Flower: Identifiable, Equatable {
  let id = UUID()
  var position: CGPoint
  var scale: CGFloat = 1.0
  var rotation: Double = 0.0
  var seed: Double
  var creationTime: TimeInterval = Date().timeIntervalSince1970
  var stemHeight: CGFloat = 120.0  // Height from ground to flower head

  init(position: CGPoint, seed: Double, stemHeight: CGFloat = 120.0) {
    self.position = position
    self.seed = seed
    self.stemHeight = stemHeight
  }

  // Visual properties derived from seed
  var petalCount: Int {
    return 5 + Int(seed.truncatingRemainder(dividingBy: 4))
  }

  var petalRadius: CGFloat {
    return 20 + CGFloat(seed.truncatingRemainder(dividingBy: 15))
  }

  var swayPhase: Double {
    return seed * 0.1
  }

  // Stem curve for natural variation
  var stemCurve: CGFloat {
    let curveValue = seed.truncatingRemainder(dividingBy: 100)
    return CGFloat(curveValue - 50) * 0.6  // Range from -30 to +30
  }

  // Helper to get color based on current palette
  func color(palette: ColorPalette) -> Color {
    return palette.randomColor(seed: seed)
  }

  // Physics simulation for ultra-smooth, heavy fluid wind
  func currentHeadPosition(time: TimeInterval, windStrength: Double, windDirection: Double)
    -> CGPoint
  {
    // "Heavy" air feeling - very slow but large movement
    let flowSpeed = 0.05  // Extremely slow cycle
    let flowAmount = 12.0  // Large idle sway

    // Smooth sine wave for idle movement
    let flowX = sin(time * flowSpeed + swayPhase) * flowAmount
    let flowY = cos(time * flowSpeed * 0.5 + swayPhase) * (flowAmount * 0.4)

    // Dramatic wind lean (increased significantly)
    // Using power function to make strong wind feel exponential
    let leanFactor = windStrength * 2.5  // Much stronger multiplier

    let windLeanX = cos(windDirection) * leanFactor
    let windLeanY = sin(windDirection) * leanFactor * 0.4

    return CGPoint(
      x: position.x + windLeanX + flowX,
      y: position.y + windLeanY + flowY
    )
  }

  func glowPulse(at time: TimeInterval) -> Double {
    return (sin(time * 2 + swayPhase) + 1) * 0.5
  }
}
