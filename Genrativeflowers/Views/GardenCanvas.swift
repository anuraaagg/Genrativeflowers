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

          // 2. Draw Grass (Behind stems)
          drawGrass(context: context, size: size, time: now)

          // 3. Draw Stems
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
    let backX = CGFloat(roll * 20)
    let backY = CGFloat(pitch * 20)

    // "Magical Night" Background Gradient
    let rect = CGRect(origin: .zero, size: size)
    let center = CGPoint(x: size.width / 2 + backX, y: size.height / 2 + backY)

    // Radial glow
    let gradient = Gradient(colors: [
      Color(red: 0.05, green: 0.1, blue: 0.2).opacity(0.4),
      Color.black.opacity(0.8),
    ])

    context.fill(
      Path(rect),
      with: .radialGradient(
        gradient,
        center: center,
        startRadius: 0,
        endRadius: size.height * 0.8
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

    // Stem Gradient: #14757a to #39c6d6
    let stemGradient = Gradient(colors: [
      Color(red: 0.08, green: 0.46, blue: 0.48),  // #14757a
      Color(red: 0.22, green: 0.78, blue: 0.84),  // #39c6d6
    ])

    context.stroke(
      path,
      with: .linearGradient(
        stemGradient, startPoint: stem.points.first!, endPoint: stem.points.last!),
      lineWidth: stem.thickness
    )

    // Draw leaves
    for leaf in stem.leaves {
      drawLeaf(leaf, context: context)
    }
  }

  private func drawLeaf(_ leaf: Stem.Leaf, context: GraphicsContext) {
    // Leaf Shape: Rounded opposite corners
    var leafContext = context
    leafContext.translateBy(x: leaf.position.x, y: leaf.position.y)
    leafContext.rotate(by: Angle(radians: leaf.angle))

    let w = leaf.size * 0.8
    let h = leaf.size * 2.0

    // Custom path for the leaf shape
    let path = Path { p in
      p.move(to: CGPoint(x: 0, y: -h / 2))
      p.addLine(to: CGPoint(x: w, y: -h / 2))
      p.addCurve(
        to: CGPoint(x: w, y: h / 2),
        control1: CGPoint(x: w, y: -h / 2 + h * 0.2),
        control2: CGPoint(x: w, y: h / 2 - h * 0.2)
      )
      p.addLine(to: CGPoint(x: 0, y: h / 2))
      p.addCurve(
        to: CGPoint(x: 0, y: -h / 2),
        control1: CGPoint(x: 0, y: h / 2 - h * 0.2),
        control2: CGPoint(x: 0, y: -h / 2 + h * 0.2)
      )
    }

    // Leaf Gradient
    let leafGradient = Gradient(colors: [
      Color(red: 0.08, green: 0.46, blue: 0.48).opacity(0.6),  // #14757a
      Color(red: 0.22, green: 0.78, blue: 0.84),  // #39c6d6
    ])

    leafContext.fill(
      path,
      with: .linearGradient(
        leafGradient, startPoint: CGPoint(x: 0, y: h / 2), endPoint: CGPoint(x: w, y: -h / 2)))
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

    // Draw stem with natural curve
    var stemPath = Path()
    stemPath.move(to: basePos)

    // Create natural curves using the flower's unique stemCurve
    let stemLength = abs(finalHeadPos.y - basePos.y)

    // Control points for a more natural S-curve or C-curve
    let control1X = basePos.x + flower.stemCurve
    let control1Y = basePos.y - stemLength * 0.33

    let control2X = finalHeadPos.x - flower.stemCurve * 0.5
    let control2Y = basePos.y - stemLength * 0.66

    let control1 = CGPoint(x: control1X, y: control1Y)
    let control2 = CGPoint(x: control2X, y: control2Y)

    stemPath.addCurve(to: finalHeadPos, control1: control1, control2: control2)

    // Stem Gradient
    let stemGradient = Gradient(colors: [
      Color(red: 0.08, green: 0.46, blue: 0.48),  // #14757a
      Color(red: 0.22, green: 0.78, blue: 0.84),  // #39c6d6
    ])

    context.stroke(
      stemPath, with: .linearGradient(stemGradient, startPoint: basePos, endPoint: finalHeadPos),
      lineWidth: 2)

    // Draw Leaves on the main stem
    let t1: CGFloat = 0.4
    let t2: CGFloat = 0.7

    let leaf1Pos = calculateCubicCurvePoint(
      t: t1, p0: basePos, c1: control1, c2: control2, p1: finalHeadPos)
    let leaf2Pos = calculateCubicCurvePoint(
      t: t2, p0: basePos, c1: control1, c2: control2, p1: finalHeadPos)

    var leafContext = context
    // Leaf 1
    leafContext.translateBy(x: leaf1Pos.x, y: leaf1Pos.y)
    leafContext.rotate(by: Angle(radians: -0.8))  // More outward
    drawStemLeaf(context: leafContext, size: 30, color: Color(red: 0.22, green: 0.78, blue: 0.84))

    // Leaf 2
    leafContext = context
    leafContext.translateBy(x: leaf2Pos.x, y: leaf2Pos.y)
    leafContext.rotate(by: Angle(radians: 0.8))  // More outward
    leafContext.scaleBy(x: -1, y: 1)  // Flip
    drawStemLeaf(context: leafContext, size: 25, color: Color(red: 0.22, green: 0.78, blue: 0.84))

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

    // Strong white glow inside the center (under lines)
    centerContext.fill(
      Circle().path(in: CGRect(x: -8, y: -8, width: 16, height: 16)),
      with: .color(.white.opacity(0.9))
    )
    centerContext.addFilter(.blur(radius: 6))
    centerContext.fill(
      Circle().path(in: CGRect(x: -6, y: -6, width: 12, height: 12)),
      with: .color(.white)
    )

    // Draw radial lines (stamens) with color variation
    let stamenCount = 12
    let stamenRadius: CGFloat = 14.0

    for i in 0..<stamenCount {
      let angle = (Double.pi * 2 / Double(stamenCount)) * Double(i)
      let startX = cos(angle) * 3.0
      let startY = sin(angle) * 3.0
      let endX = cos(angle) * stamenRadius
      let endY = sin(angle) * stamenRadius

      let path = Path { p in
        p.move(to: CGPoint(x: startX, y: startY))
        p.addLine(to: CGPoint(x: endX, y: endY))
      }

      // Get a darkened version of the flower color for stamens
      let stamenColor = color.opacity(0.7)

      // Draw subtle white outline first for separation from glow
      centerContext.stroke(
        path,
        with: .color(.white.opacity(0.4)),
        lineWidth: 2.5
      )

      // Draw colored line on top
      centerContext.stroke(
        path,
        with: .color(stamenColor),
        lineWidth: 1.5
      )

      // Dot at the end with flower color
      let dotRect = CGRect(x: endX - 3, y: endY - 3, width: 6, height: 6)

      // Glow around dot
      centerContext.fill(
        Circle().path(in: dotRect.insetBy(dx: -1, dy: -1)),
        with: .color(color.opacity(0.3))
      )
      centerContext.addFilter(.blur(radius: 1))

      // Colored dot on top
      centerContext.fill(
        Circle().path(in: dotRect),
        with: .color(color.opacity(0.9))
      )
    }

    // 5. Fireflies (Glowing dots)
    let lightCount = 8
    for i in 0..<lightCount {
      let speed = 2.0
      let offset = Double(i) * (Double.pi * 2 / Double(lightCount))
      let orbitRadius = baseRadius * 1.2

      let lx = cos(time * speed + offset) * orbitRadius
      let ly = sin(time * speed + offset) * orbitRadius * 0.5

      let pulse = (sin(time * 4 + offset) + 1) * 0.5
      let lightSize = 3.0 + pulse * 3.0

      let lightColor =
        i % 2 == 0
        ? Color(red: 1.0, green: 0.98, blue: 0.0) : Color(red: 0.14, green: 0.94, blue: 1.0)

      var lightContext = context
      lightContext.translateBy(x: finalHeadPos.x, y: finalHeadPos.y)  // Center on flower head
      lightContext.addFilter(.blur(radius: 2))
      lightContext.fill(
        Circle().path(
          in: CGRect(
            x: lx - lightSize / 2, y: ly - lightSize / 2, width: lightSize, height: lightSize)),
        with: .color(lightColor)
      )
    }
  }

  private func calculateQuadCurvePoint(t: CGFloat, p0: CGPoint, c: CGPoint, p1: CGPoint) -> CGPoint
  {
    let x = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * c.x + t * t * p1.x
    let y = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * c.y + t * t * p1.y
    return CGPoint(x: x, y: y)
  }

  private func calculateCubicCurvePoint(
    t: CGFloat, p0: CGPoint, c1: CGPoint, c2: CGPoint, p1: CGPoint
  ) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    let mt = 1 - t
    let mt2 = mt * mt
    let mt3 = mt2 * mt

    let x = mt3 * p0.x + 3 * mt2 * t * c1.x + 3 * mt * t2 * c2.x + t3 * p1.x
    let y = mt3 * p0.y + 3 * mt2 * t * c1.y + 3 * mt * t2 * c2.y + t3 * p1.y

    return CGPoint(x: x, y: y)
  }

  private func drawStemLeaf(context: GraphicsContext, size: CGFloat, color: Color) {
    let w = size * 0.6
    let h = size

    let path = Path { p in
      p.move(to: CGPoint(x: 0, y: 0))
      p.addCurve(
        to: CGPoint(x: w, y: -h),
        control1: CGPoint(x: w * 0.2, y: -h * 0.2),
        control2: CGPoint(x: w, y: -h * 0.8)
      )
      p.addCurve(
        to: CGPoint(x: 0, y: 0),
        control1: CGPoint(x: w * 0.8, y: -h * 0.2),
        control2: CGPoint(x: 0, y: -h * 0.2)
      )
    }

    context.fill(
      path,
      with: .linearGradient(
        Gradient(colors: [color.opacity(0.4), color]),
        startPoint: CGPoint(x: 0, y: 0),
        endPoint: CGPoint(x: w, y: -h)
      ))
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

  private func drawGrass(context: GraphicsContext, size: CGSize, time: TimeInterval) {
    let grassCount = 60
    let width = size.width
    let groundY = size.height * appState.baselineY

    // Use a stable random generator based on index
    for i in 0..<grassCount {
      var random = SeededRandom(seed: UInt64(i * 999))

      let xPos = random.nextCGFloat(in: -50...width + 50)
      let bladeHeight = random.nextCGFloat(in: 60...140)
      let bladeWidth = random.nextCGFloat(in: 4...8)
      let angle = random.nextDouble(in: -0.2...0.2)
      let swaySpeed = random.nextDouble(in: 1.0...3.0)
      let swayPhase = random.nextDouble(in: 0...Double.pi * 2)

      // Wind sway
      let windSway =
        sin(time * swaySpeed + swayPhase) * 5.0
        + (appState.wind.strength * 0.2 * cos(appState.wind.direction))

      var bladeContext = context
      bladeContext.translateBy(x: xPos, y: groundY + 10)  // Slightly below baseline to hide bottom
      bladeContext.rotate(by: Angle(radians: angle))

      // Blade Path
      let path = Path { p in
        p.move(to: CGPoint(x: 0, y: 0))
        p.addCurve(
          to: CGPoint(x: windSway, y: -bladeHeight),
          control1: CGPoint(x: bladeWidth / 2, y: -bladeHeight * 0.3),
          control2: CGPoint(x: windSway * 0.5, y: -bladeHeight * 0.7)
        )
        p.addLine(to: CGPoint(x: bladeWidth, y: 0))
      }

      // Gradient
      let grassGradient = Gradient(colors: [
        Color(red: 0.05, green: 0.3, blue: 0.35),  // Darker base
        Color(red: 0.15, green: 0.65, blue: 0.7),  // Lighter tip
      ])

      bladeContext.fill(
        path,
        with: .linearGradient(
          grassGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: -bladeHeight)))
    }

    // Add a dark overlay gradient at the very bottom to blend roots
    // Add a dark overlay gradient at the very bottom to blend roots
    // Since groundY is now at the bottom (size.height), we need to draw up from there
    let bottomRect = CGRect(x: 0, y: groundY - 40, width: width, height: 40)
    context.fill(
      Path(bottomRect),
      with: .linearGradient(
        Gradient(colors: [.clear, Color.black.opacity(0.8)]),
        startPoint: CGPoint(x: 0, y: groundY - 40),
        endPoint: CGPoint(x: 0, y: groundY)
      ))
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
