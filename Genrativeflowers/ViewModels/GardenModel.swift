//
//  GardenModel.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Foundation
import SwiftUI

/// Observable view model managing the flower garden state
@Observable
class GardenModel {
  var flowers: [Flower] = []

  // Visual parameters
  var bloomIntensity: Double = 1.2
  var chromaticOffset: Double = 6.0
  var showStars: Bool = true
  var globalScale: CGFloat = 1.0

  // Wind physics
  var windStrength: Double = 20.0  // 0-100
  var windDirection: Double = 0.0  // Radians
  private var windDecayRate: Double = 0.95  // Per second

  // Color palette
  var currentPalette: ColorPalette = .neon

  // Gyro wind control
  var isGyroWindEnabled: Bool = true

  // Drawing mode
  var isDrawingMode: Bool = false
  var currentStemPath: [CGPoint] = []

  // Motion manager
  let motionManager = MotionManager()

  private(set) var currentTime: TimeInterval = Date().timeIntervalSince1970

  /// Updates the current time (called each frame)
  func updateTime(_ time: TimeInterval) {
    currentTime = time

    // Apply wind decay
    windStrength *= windDecayRate
    if windStrength < 0.1 {
      windStrength = 0
    }
  }

  /// Adds a new flower at the specified position (tap-to-spawn)
  func addFlower(at position: CGPoint) {
    let flower = Flower(position: position)
    flowers.append(flower)
  }

  /// Adds a flower from a drawn stem path
  func addFlowerFromStem(path: [CGPoint]) {
    guard let headPosition = path.last else { return }
    let flower = Flower(position: headPosition, stemPath: path)
    flowers.append(flower)
  }

  /// Adds a random flower at a random position within the given size
  func addRandomFlower(in size: CGSize) {
    let x = CGFloat.random(in: 50...(size.width - 50))
    let y = CGFloat.random(in: 100...(size.height - 200))
    addFlower(at: CGPoint(x: x, y: y))
  }

  /// Removes the specified flower
  func removeFlower(_ flower: Flower) {
    flowers.removeAll { $0.id == flower.id }
  }

  /// Removes all flowers
  func clearAll() {
    flowers.removeAll()
  }

  /// Cycle to the next color palette
  func cyclePalette() {
    currentPalette = currentPalette.next
  }

  /// Apply wind impulse from rotation gesture
  func applyWindImpulse(strength: Double, direction: Double) {
    windStrength = min(100, windStrength + strength)
    windDirection = direction
  }

  /// Apply gyro-based wind adjustment
  func updateWindFromGyro() {
    guard isGyroWindEnabled else { return }

    let gyroRate = motionManager.gyroRotationRate
    windDirection += gyroRate * 0.1  // Small adjustment
    windStrength = min(100, windStrength + abs(gyroRate) * 2)
  }

  /// Moves the specified flower to a new position
  func moveFlower(_ flower: Flower, to position: CGPoint) {
    if let index = flowers.firstIndex(where: { $0.id == flower.id }) {
      flowers[index].position = position
    }
  }

  /// Finds the nearest flower to the given point within the threshold
  func findNearestFlower(to point: CGPoint, threshold: CGFloat = 48) -> Flower? {
    var nearestFlower: Flower?
    var minDistance: CGFloat = threshold

    for flower in flowers {
      let headPosition = flower.currentHeadPosition(
        time: currentTime,
        windStrength: windStrength,
        windDirection: windDirection
      )
      let distance = hypot(point.x - headPosition.x, point.y - headPosition.y)

      if distance < minDistance {
        minDistance = distance
        nearestFlower = flower
      }
    }

    return nearestFlower
  }
}
