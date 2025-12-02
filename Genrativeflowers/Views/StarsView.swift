//
//  StarsView.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

/// Renders a starry cosmic background with twinkling animation
struct StarsView: View {
  let size: CGSize
  let starCount: Int = 150
  @State private var twinklePhase: Double = 0

  var body: some View {
    TimelineView(.animation) { timeline in
      Canvas { context, size in
        let time = timeline.date.timeIntervalSince1970

        // Use seeded random for consistent star positions
        var random = SeededRandom(seed: 42)

        for i in 0..<starCount {
          let x = random.nextCGFloat(in: 0...size.width)
          let y = random.nextCGFloat(in: 0...size.height)
          let baseSize = random.nextCGFloat(in: 0.5...2.5)
          let twinkleSpeed = random.nextDouble(in: 0.8...2.0)
          let phase = random.nextDouble(in: 0...(Double.pi * 2))

          // Twinkle animation
          let twinkle = (sin(time * twinkleSpeed + phase) + 1) / 2
          let starSize = baseSize * (0.6 + CGFloat(twinkle) * 0.4)
          let opacity = 0.4 + twinkle * 0.6

          let rect = CGRect(
            x: x - starSize / 2,
            y: y - starSize / 2,
            width: starSize,
            height: starSize
          )

          context.fill(
            Circle().path(in: rect),
            with: .color(.white.opacity(opacity))
          )
        }
      }
    }
    .frame(width: size.width, height: size.height)
    .ignoresSafeArea()
  }
}
