//
//  SeededRandom.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import CoreGraphics
import Foundation

/// Utility for seeded pseudo-random number generation
struct SeededRandom {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  /// Generates the next random UInt64 using a simple LCG algorithm
  mutating func next() -> UInt64 {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    return state
  }

  /// Returns a random Double in the range [0, 1)
  mutating func nextDouble() -> Double {
    Double(next()) / Double(UInt64.max)
  }

  /// Returns a random Double in the specified range
  mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
    let value = nextDouble()
    return range.lowerBound + value * (range.upperBound - range.lowerBound)
  }

  /// Returns a random CGFloat in the specified range
  mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
    CGFloat(nextDouble(in: Double(range.lowerBound)...Double(range.upperBound)))
  }

  /// Returns a random Int in the specified range
  mutating func nextInt(in range: ClosedRange<Int>) -> Int {
    let value = nextDouble()
    let rangeSize = Double(range.upperBound - range.lowerBound + 1)
    return range.lowerBound + Int(value * rangeSize)
  }
}
