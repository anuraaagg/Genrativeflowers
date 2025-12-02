//
//  HapticManager.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import UIKit

/// Manages haptic feedback for interactions
class HapticManager {
  static let shared = HapticManager()

  private let lightImpact = UIImpactFeedbackGenerator(style: .light)
  private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
  private let softImpact = UIImpactFeedbackGenerator(style: .soft)
  private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
  private let notificationGenerator = UINotificationFeedbackGenerator()

  private init() {
    // Prepare generators
    lightImpact.prepare()
    rigidImpact.prepare()
    softImpact.prepare()
    heavyImpact.prepare()
    notificationGenerator.prepare()
  }

  // MARK: - Haptic Methods

  /// Light impact (e.g., tap to spawn flower)
  func light() {
    lightImpact.impactOccurred()
    lightImpact.prepare()
  }

  /// Rigid impact (e.g., enter drawing mode)
  func rigid() {
    rigidImpact.impactOccurred()
    rigidImpact.prepare()
  }

  /// Soft impact (e.g., release drawing mode)
  func soft() {
    softImpact.impactOccurred()
    softImpact.prepare()
  }

  /// Heavy impact (e.g., reset confirmation)
  func heavy() {
    heavyImpact.impactOccurred()
    heavyImpact.prepare()
  }

  /// Success notification (e.g., palette cycle)
  func success() {
    notificationGenerator.notificationOccurred(.success)
    notificationGenerator.prepare()
  }

  /// Warning notification (e.g., reset canceled)
  func warning() {
    notificationGenerator.notificationOccurred(.warning)
    notificationGenerator.prepare()
  }
}
