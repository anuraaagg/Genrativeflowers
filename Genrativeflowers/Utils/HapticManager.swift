//
//  HapticManager.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import UIKit

class HapticManager {
  static let shared = HapticManager()

  private let impactLight = UIImpactFeedbackGenerator(style: .light)
  private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
  private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
  private let notification = UINotificationFeedbackGenerator()
  private let selection = UISelectionFeedbackGenerator()

  private init() {
    // Prepare generators to reduce latency
    impactLight.prepare()
    impactMedium.prepare()
    impactHeavy.prepare()
    notification.prepare()
    selection.prepare()
  }

  func light() {
    impactLight.impactOccurred()
  }

  func medium() {
    impactMedium.impactOccurred()
  }

  func heavy() {
    impactHeavy.impactOccurred()
  }

  func success() {
    notification.notificationOccurred(.success)
  }

  func warning() {
    notification.notificationOccurred(.warning)
  }

  func error() {
    notification.notificationOccurred(.error)
  }

  func selectionChanged() {
    selection.selectionChanged()
  }
}
