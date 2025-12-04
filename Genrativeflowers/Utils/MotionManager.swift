//
//  MotionManager.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Combine
import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
  static let shared = MotionManager()

  private let motionManager = CMMotionManager()

  // Published values for UI binding
  @Published var pitch: Double = 0.0
  @Published var roll: Double = 0.0
  @Published var gyroRotationRate: Double = 0.0

  // Smoothing factor (Low-pass filter)
  private let alpha: Double = 0.05

  init() {
    startMotionUpdates()
  }

  func startMotionUpdates() {
    // Device Motion (Accelerometer + Gyro fused)
    if motionManager.isDeviceMotionAvailable {
      motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
      motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
        guard let self = self, let motion = motion else { return }

        // Apply low-pass filter for smoothing
        // x_t = x_{t-1} * (1 - α) + x_measure * α

        self.pitch = self.pitch * (1 - self.alpha) + motion.attitude.pitch * self.alpha
        self.roll = self.roll * (1 - self.alpha) + motion.attitude.roll * self.alpha
      }
    }

    // Raw Gyro for wind control (rotation rate)
    if motionManager.isGyroAvailable {
      motionManager.gyroUpdateInterval = 1.0 / 60.0
      motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
        guard let self = self, let data = data else { return }

        // We use rotation around Z axis (yaw-like) for wind direction influence
        // Or simply use the magnitude of rotation to stir the wind
        let rotationRate = data.rotationRate.z

        // Smooth the gyro data too
        self.gyroRotationRate = self.gyroRotationRate * (1 - self.alpha) + rotationRate * self.alpha
      }
    }
  }

  func stopUpdates() {
    motionManager.stopDeviceMotionUpdates()
    motionManager.stopGyroUpdates()
  }

  deinit {
    stopUpdates()
  }
}
