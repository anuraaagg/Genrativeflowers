//
//  GardenCanvas.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Combine
import SwiftUI

struct GardenCanvas: View {
  @ObservedObject var appState: AppState

  // Timeline for animation loop
  @State private var time: TimeInterval = 0
  let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      TimelineView(.animation) { timeline in
        Canvas { context, size in
          let now = timeline.date.timeIntervalSinceReferenceDate

          // 1. Draw Background / Parallax Layers
          if appState.parallaxEnabled {
            drawParallaxBackground(context: context, size: size)
          }

          // 2. Draw Stems
          for stem in appState.stems {
            drawStem(stem, context: context)
          }

          // 3. Draw Flowers
          for flower in appState.flowers {
            drawFlower(flower, context: context, size: size, time: now)
          }

          // 4. Draw Active Drawing Path
          if case .drawing = appState.activeGesture, !appState.stems.isEmpty,
            let lastStem = appState.stems.last
          {
            // Ideally we'd have a separate temporary path in AppState,
            // but for now we can just draw the last stem if it's being created.
            // However, the spec says "While holding + dragging: Draw a Bezier path".
            // We'll implement the gesture logic in the parent or overlay.
          }
        }
      }
      // Gestures will be handled by an overlay or the view itself
      .gesture(
        TapGesture()
          .onEnded {
            // We need location, so we might need a different approach for Tap
            // or use a spatial tap gesture if available (iOS 16+) or GeometryReader overlay
          }
      )
      .onReceive(timer) { input in
        time = input.timeIntervalSince1970

        // Update wind physics
        if appState.gyroWindEnabled {
          let gyro = appState.motionManager.gyroRotationRate
          appState.wind.direction += gyro * 0.1
          appState.wind.strength = min(100, appState.wind.strength + abs(gyro) * 2)
        }

        // Decay wind
        appState.wind.strength *= appState.wind.decay
      }
    }
  }

  // MARK: - Drawing Methods

  private func drawParallaxBackground(context: GraphicsContext, size: CGSize) {
    let pitch = appState.motionManager.pitch
    let roll = appState.motionManager.roll

    // Background offset (max 2px)
    let backX = CGFloat(roll * 20)  // amplified for visibility
    let backY = CGFloat(pitch * 20)

    // Draw some distant shapes or gradient
    // For now, just a subtle gradient shift
    let gradient = Gradient(colors: [
      Color.blue.opacity(0.1),
      Color.purple.opacity(0.05),
    ])

    context.fill(
      Path(CGRect(origin: .zero, size: size)),
      with: .linearGradient(
        gradient,
        startPoint: CGPoint(x: size.width / 2 + backX, y: 0 + backY),
        endPoint: CGPoint(x: size.width / 2 - backX, y: size.height - backY)
      )
    )
  }

  private func drawStem(_ stem: Stem, context: GraphicsContext) {
    guard stem.points.count > 1 else { return }

    var path = Path()
    path.move(to: stem.points[0])

    for i in 1..<stem.points.count {
      path.addLine(to: stem.points[i])
    }

    // Smooth the path if possible, or use QuadCurve in the model

    context.stroke(
      path,
      with: .color(Color.green.opacity(0.6)),
      lineWidth: stem.thickness
    )

    // Draw leaves
    for leaf in stem.leaves {
      drawLeaf(leaf, context: context)
    }
  }

  private func drawLeaf(_ leaf: Stem.Leaf, context: GraphicsContext) {
    // Simple leaf shape
    var path = Path()
    let size = leaf.size
    let rect = CGRect(x: -size / 2, y: -size, width: size, height: size * 2)
    path.addEllipse(in: rect)

    var leafContext = context
    leafContext.translateBy(x: leaf.position.x, y: leaf.position.y)
    leafContext.rotate(by: Angle(radians: leaf.angle))

    leafContext.fill(path, with: .color(Color.green.opacity(0.8)))
  }

  private func drawFlower(
    _ flower: Flower, context: GraphicsContext, size: CGSize, time: TimeInterval
  ) {
    // Stems always start from bottom baseline
    let groundY = size.height * appState.baselineY
    let basePos = CGPoint(x: flower.position.x, y: groundY)

    // Flower head is at the tap position
    let headY = flower.position.y

    // Apply wind sway to head position
    let swayedHeadPos = flower.currentHeadPosition(
      time: time,
      windStrength: appState.wind.strength,
      windDirection: appState.wind.direction
    )

    // Use the swayed position
    let finalHeadPos = swayedHeadPos

    // Draw stem
    var stemPath = Path()
    stemPath.move(to: basePos)

    // Control point for curve
    let midX = (basePos.x + finalHeadPos.x) / 2
    let midY = (basePos.y + finalHeadPos.y) / 2
    let control = CGPoint(x: midX + (finalHeadPos.x - basePos.x) * 0.2, y: midY)

    stemPath.addQuadCurve(to: finalHeadPos, control: control)

    context.stroke(stemPath, with: .color(Color.green.opacity(0.5)), lineWidth: 2)

    // Draw Flower Head with Fluid Chromatic Aberration (RGB Split)
    let color = flower.color(palette: appState.palette)
    let petalCount = flower.petalCount
    let baseRadius = flower.petalRadius * flower.scale * CGFloat(appState.bloomIntensity)
    let chromaticOffset = CGFloat(appState.chromaticOffset)

    // We use additive blending (.plusLighter) to merge RGB channels into white/bright colors
    // This creates the "fluid" light effect where they overlap, and rainbow fringes where they don't.

    // 1. Red Channel (Offset Left/Top)
    var redContext = context
    redContext.blendMode = .plusLighter
    redContext.translateBy(x: finalHeadPos.x - chromaticOffset, y: finalHeadPos.y - chromaticOffset)
    redContext.rotate(by: Angle(radians: flower.rotation))
    // Slight blur for "fluid" feel, not "blurry"
    redContext.addFilter(.blur(radius: 2))

    drawPetals(
      context: redContext,
      count: petalCount,
      radius: baseRadius,
      color: Color(red: 1, green: 0, blue: 0).opacity(0.8)
    )

    // 2. Green Channel (Center)
    var greenContext = context
    greenContext.blendMode = .plusLighter
    greenContext.translateBy(x: finalHeadPos.x, y: finalHeadPos.y)
    greenContext.rotate(by: Angle(radians: flower.rotation))
    greenContext.addFilter(.blur(radius: 2))

    drawPetals(
      context: greenContext,
      count: petalCount,
      radius: baseRadius,
      color: Color(red: 0, green: 1, blue: 0).opacity(0.8)
    )

    // 3. Blue Channel (Offset Right/Bottom)
    var blueContext = context
    blueContext.blendMode = .plusLighter
    blueContext.translateBy(
      x: finalHeadPos.x + chromaticOffset, y: finalHeadPos.y + chromaticOffset)
    blueContext.rotate(by: Angle(radians: flower.rotation))
    blueContext.addFilter(.blur(radius: 2))

    drawPetals(
      context: blueContext,
      count: petalCount,
      radius: baseRadius,
      color: Color(red: 0, green: 0, blue: 1).opacity(0.8)
    )

    // 4. Core White/Color Overlay (Soft)
    // This adds the actual flower color tint on top of the light interference
    var mainContext = context
    mainContext.blendMode = .plusLighter  // Keep it glowing
    mainContext.translateBy(x: finalHeadPos.x, y: finalHeadPos.y)
    mainContext.rotate(by: Angle(radians: flower.rotation))
    mainContext.addFilter(.blur(radius: 4))  // Softer glow for the core

    drawPetals(
      context: mainContext,
      count: petalCount,
      radius: baseRadius * 0.9,
      color: color.opacity(0.6)
    )


    // Radial lines center (stamens)
    var centerContext = context
    centerContext.translateBy(x: finalHeadPos.x, y: finalHeadPos.y)

    // Strong white glow inside the center (behind lines)
    centerContext.fill(
      Circle().path(in: CGRect(x: -8, y: -8, width: 16, height: 16)),
      with: .color(.white.opacity(0.9))
    )
    centerContext.addFilter(.blur(radius: 6))
    centerContext.fill(
      Circle().path(in: CGRect(x: -6, y: -6, width: 12, height: 12)),
      with: .color(.white)
    )

    // Draw radial lines (stamens) - make them darker and more pronounced
    let stamenCount = 12
    let stamenRadius: CGFloat = 12.0

    for i in 0..<stamenCount {
      let angle = (Double.pi * 2 / Double(stamenCount)) * Double(i)
      let startX = cos(angle) * 2.0
      let startY = sin(angle) * 2.0
      let endX = cos(angle) * stamenRadius
      let endY = sin(angle) * stamenRadius

      let path = Path { p in
        p.move(to: CGPoint(x: startX, y: startY))
        p.addLine(to: CGPoint(x: endX, y: endY))
      }

      centerContext.stroke(
        path,
        with: .color(Color(red: 0.05, green: 0.05, blue: 0.15)),
        lineWidth: 2.0
      )

      // Larger dot at the end of each stamen
      let dotRect = CGRect(x: endX - 2, y: endY - 2, width: 4, height: 4)
      centerContext.fill(
        Circle().path(in: dotRect), with: .color(Color(red: 0.1, green: 0.1, blue: 0.2)))
    }
  }

  private func drawPetals(context: GraphicsContext, count: Int, radius: CGFloat, color: Color) {
    for i in 0..<count {
      let angle = (Double.pi * 2 / Double(count)) * Double(i)
      var petalContext = context
      petalContext.rotate(by: Angle(radians: angle))

      // Petal shape: Ellipse
      let petalRect = CGRect(x: 0, y: -radius / 4, width: radius, height: radius / 2)
      petalContext.fill(Ellipse().path(in: petalRect), with: .color(color))
    }
  }
}

// Extension to get hue component from Color
extension Color {
  var hueComponent: Double {
    var hue: CGFloat = 0
    UIColor(self).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
    return Double(hue)
  }
}
