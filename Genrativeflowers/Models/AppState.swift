//
//  AppState.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Combine
import SwiftUI

/// Single source of truth for the application state
@MainActor
class AppState: ObservableObject {
  // MARK: - Data Models
  @Published var flowers: [Flower] = []
  @Published var stems: [Stem] = []
  @Published var palette: ColorPalette = .pastel

  // MARK: - Physics & Environment
  @Published var wind: WindState = WindState()
  @Published var parallaxEnabled: Bool = true
  @Published var gyroWindEnabled: Bool = true
  @Published var showStars: Bool = true

  // MARK: - Visual Settings
  @Published var bloomIntensity: Double = 1.2
  @Published var chromaticOffset: Double = 6.0

  // MARK: - Interaction State
  @Published var activeGesture: GestureType = .none
  @Published var showControlPanel: Bool = false
  @Published var showResetConfirmation: Bool = false

  // MARK: - Services
  let motionManager = MotionManager.shared
  let hapticManager = HapticManager.shared

  // MARK: - Limits
  let maxFlowers = 60
  let maxStems = 30
  let baselineY: CGFloat = 0.78  // 78% of screen height

  // MARK: - Actions

  func spawnFlower(at point: CGPoint, screenSize: CGSize) -> UUID {
    // Enforce limits
    if flowers.count >= maxFlowers {
      flowers.removeFirst()
    }

    // Snap to baseline if below it
    let baseline = screenSize.height * baselineY
    let y = point.y > baseline ? baseline : point.y
    let finalPoint = CGPoint(x: point.x, y: y)

    let flower = Flower(position: finalPoint, seed: Double.random(in: 0...1000))
    flowers.append(flower)

    hapticManager.light()

    return flower.id  // Return the ID of the newly created flower
  }

  func cyclePalette() {
    palette = palette.next
    hapticManager.success()

    // Tint existing flowers (this would be handled in the view/rendering layer usually,
    // but we can trigger an update here or just let the view react to 'palette')
  }

  func clearAll() {
    flowers.removeAll()
    stems.removeAll()
    wind = WindState()  // Reset wind
    hapticManager.success()
  }

  func resetToDefaults() {
    clearAll()
    palette = .pastel
    bloomIntensity = 1.2
    chromaticOffset = 6.0
    wind = WindState()
  }

  // MARK: - Growing Logic
  private var growTimer: AnyCancellable?

  func startGrowing(flowerId: UUID) {
    // Cancel existing timer if any
    stopGrowing()

    growTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
      .sink { [weak self] _ in
        guard let self = self else { return }
        if let index = self.flowers.firstIndex(where: { $0.id == flowerId }) {
          // Increase scale up to a limit
          if self.flowers[index].scale < 2.5 {
            self.flowers[index].scale += 0.05
            self.hapticManager.light()
          }
        }
      }
  }

  func stopGrowing() {
    growTimer?.cancel()
    growTimer = nil
  }
}

class WindState: ObservableObject {
  @Published var direction: Double = 0.0  // Radians
  @Published var strength: Double = 5.0  // 0-100, gentler default
  var decay: Double = 0.98  // Slower decay for smoother motion
}

enum GestureType: Equatable {
  case none
  case drawing
  case rotating
  case selectedFlower(UUID)
}
