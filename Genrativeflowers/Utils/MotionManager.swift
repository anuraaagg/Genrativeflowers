//
//  MotionManager.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Combine
import CoreMotion
import Foundation

/// Manages device motion for parallax and gyro-based wind control
@Observable
class MotionManager {
  private let motionManager = CMMotionManager()

  // Tilt (for parallax)
  var tiltX: Double = 0.0
  var tiltY: Double = 0.0

  // Gyro (for wind direction when rotating)
  var gyroRotationRate: Double = 0.0

  private let lowPassAlpha: Double = 0.05  // Smoothing factor

  init() {
    startMonitoring()
  }

  func startMonitoring() {
    guard motionManager.isDeviceMotionAvailable else {
      print("⚠️ Device motion not available")
      return
    }

    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0  // 60 Hz

    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
      guard let self = self, let motion = motion else { return }

      // Low-pass filter for smooth tilt
      let rawTiltX = motion.gravity.x
      let rawTiltY = motion.gravity.y

      self.tiltX = self.tiltX * (1 - self.lowPassAlpha) + rawTiltX * self.lowPassAlpha
      self.tiltY = self.tiltY * (1 - self.lowPassAlpha) + rawTiltY * self.lowPassAlpha

      // Gyro rotation rate (z-axis)
      self.gyroRotationRate = motion.rotationRate.z
    }
  }

  func stopMonitoring() {
    motionManager.stopDeviceMotionUpdates()
  }

  deinit {
    stopMonitoring()
  }
}
