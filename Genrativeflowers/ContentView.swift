//
//  ContentView.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import SwiftUI

struct ContentView: View {
  @State private var model = GardenModel()
  @GestureState private var magnification: CGFloat = 1.0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background gradient
        LinearGradient(
          colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.1, green: 0.05, blue: 0.2),
            Color(red: 0.15, green: 0.1, blue: 0.25),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        // Stars layer
        if model.showStars {
          StarsView(size: geometry.size)
            .allowsHitTesting(false)  // Don't block taps - let them pass through to canvas
        }

        // Main flower canvas
        TimelineView(.animation) { timeline in
          Canvas { context, size in
            let time = timeline.date.timeIntervalSince1970
            model.updateTime(time)

            // Apply global scale
            var scaledContext = context
            scaledContext.scaleBy(
              x: model.globalScale * magnification, y: model.globalScale * magnification)

            // Draw fog/mist layer at bottom
            drawFogLayer(context: scaledContext, size: size)

            // Draw all flowers
            for flower in model.flowers {
              drawFlower(flower, context: scaledContext, size: size, time: time)
            }

            // Draw grain overlay
            drawGrainOverlay(context: scaledContext, size: size, time: time)
          }
        }
        // Double-tap to cycle palette
        .onTapGesture(count: 2) {
          model.cyclePalette()
          HapticManager.shared.success()
        }
        // Single tap to spawn flower
        .onTapGesture(count: 1) { location in
          model.addFlower(at: location)
          HapticManager.shared.light()
        }
        // Pinch to scale scene
        .gesture(
          MagnificationGesture()
            .updating($magnification) { value, state, _ in
              state = value
            }
            .onEnded { value in
              model.globalScale *= value
            }
        )
        .overlay(alignment: .bottomTrailing) {
          // Control panel - using overlay so it doesn't block canvas gestures
          ControlPanel(model: model, canvasSize: geometry.size)
            .padding()
        }
      }
    }
    .preferredColorScheme(.dark)
  }

  // MARK: - Drawing Functions

  private func drawFogLayer(context: GraphicsContext, size: CGSize) {
    let fogHeight: CGFloat = 200
    let fogRect = CGRect(x: 0, y: size.height - fogHeight, width: size.width, height: fogHeight)

    let gradient = Gradient(colors: [
      Color.white.opacity(0),
      Color(red: 0.7, green: 0.8, blue: 0.9).opacity(0.15),
      Color(red: 0.6, green: 0.7, blue: 0.85).opacity(0.25),
    ])

    context.fill(
      Path(fogRect),
      with: .linearGradient(
        gradient,
        startPoint: CGPoint(x: size.width / 2, y: size.height - fogHeight),
        endPoint: CGPoint(x: size.width / 2, y: size.height)
      )
    )
  }

  private func drawGrainOverlay(context: GraphicsContext, size: CGSize, time: TimeInterval) {
    var random = SeededRandom(seed: UInt64(time * 10))

    for _ in 0..<500 {
      let x = random.nextCGFloat(in: 0...size.width)
      let y = random.nextCGFloat(in: 0...size.height)
      let opacity = random.nextDouble(in: 0.02...0.08)

      let rect = CGRect(x: x, y: y, width: 1, height: 1)
      context.fill(
        Circle().path(in: rect),
        with: .color(.white.opacity(opacity))
      )
    }
  }

  private func drawFlower(
    _ flower: Flower, context: GraphicsContext, size: CGSize, time: TimeInterval
  ) {
    // Calculate current head position with wind effects
    let headPosition = flower.currentHeadPosition(
      time: time,
      windStrength: model.windStrength,
      windDirection: model.windDirection
    )
    let pulse = flower.glowPulse(at: time)

    // Skip if off screen
    guard headPosition.y > -100 && headPosition.y < size.height + 100 else { return }

    // Draw stem from base to head
    let basePoint = CGPoint(x: flower.baseX, y: size.height - 50)  // Ground level
    drawStem(
      from: basePoint,
      to: headPosition,
      color: flower.color(palette: model.currentPalette),
      context: context
    )

    // Draw flower head with chromatic aberration
    drawFlowerHead(
      flower: flower,
      center: headPosition,
      pulse: pulse,
      context: context
    )

    // Draw floating orb
    let orbY = headPosition.y - 30 - CGFloat(sin(time * 1.5 + flower.swayPhase)) * 8
    let orbCenter = CGPoint(x: headPosition.x, y: orbY)
    drawFloatingOrb(center: orbCenter, flower: flower, context: context)
  }

  private func drawStem(
    from start: CGPoint, to end: CGPoint, color: Color, context: GraphicsContext
  ) {
    var path = Path()

    // Create curved stem
    let controlPoint = CGPoint(
      x: (start.x + end.x) / 2 + (end.x - start.x) * 0.1,
      y: (start.y + end.y) / 2
    )

    path.move(to: start)
    path.addQuadCurve(to: end, control: controlPoint)

    // Desaturated stem color
    let stemColor = Color(
      hue: color.hueComponent,
      saturation: 0.3,
      brightness: 0.4
    )

    context.stroke(
      path,
      with: .color(stemColor),
      lineWidth: 3
    )
  }

  private func drawFlowerHead(
    flower: Flower, center: CGPoint, pulse: Double, context: GraphicsContext
  ) {
    let offset = model.chromaticOffset

    // Draw glow layers first
    let glowRadius = 40 * flower.scale * CGFloat(0.8 + pulse * 0.4) * CGFloat(model.bloomIntensity)

    for i in stride(from: 3, to: 0, by: -1) {
      let layerRadius = glowRadius * CGFloat(i) / 3
      let layerOpacity = 0.15 / Double(i + 1)

      drawPetals(
        flower: flower,
        center: center,
        offset: .zero,
        blur: layerRadius,
        opacity: layerOpacity,
        context: context
      )
    }

    // Draw chromatic aberration layers (RGB offset)
    if offset > 0 {
      // Red layer (offset left-up)
      drawPetals(
        flower: flower,
        center: center,
        offset: CGPoint(x: -offset, y: -offset),
        blur: 0,
        opacity: 0.6,
        tint: .red,
        blendMode: .screen,
        context: context
      )

      // Green layer (no offset)
      drawPetals(
        flower: flower,
        center: center,
        offset: .zero,
        blur: 0,
        opacity: 0.8,
        tint: .green,
        blendMode: .screen,
        context: context
      )

      // Blue layer (offset right-down)
      drawPetals(
        flower: flower,
        center: center,
        offset: CGPoint(x: offset, y: offset),
        blur: 0,
        opacity: 0.6,
        tint: .blue,
        blendMode: .screen,
        context: context
      )
    } else {
      // No chromatic aberration - draw normal
      drawPetals(
        flower: flower,
        center: center,
        offset: .zero,
        blur: 0,
        opacity: 1.0,
        context: context
      )
    }

    // Draw center sparkle
    drawSparkle(center: center, flower: flower, time: model.currentTime, context: context)
  }

  private func drawPetals(
    flower: Flower,
    center: CGPoint,
    offset: CGPoint,
    blur: CGFloat,
    opacity: Double,
    tint: Color? = nil,
    blendMode: GraphicsContext.BlendMode = .normal,
    context: GraphicsContext
  ) {
    var petalContext = context
    petalContext.blendMode = blendMode

    if blur > 0 {
      petalContext.addFilter(.blur(radius: blur))
    }

    let angleStep = (2 * .pi) / Double(flower.petalCount)

    for i in 0..<flower.petalCount {
      let angle = angleStep * Double(i)
      let distance = flower.petalRadius * 0.5
      let petalX = center.x + offset.x + cos(angle) * distance
      let petalY = center.y + offset.y + sin(angle) * distance

      // Create organic blob shape for petal
      let petalSize = flower.petalRadius * 1.2
      let petalCenter = CGPoint(x: petalX, y: petalY)

      // Draw petal as organic blob (ellipse with slight rotation)
      var path = Path()
      let blobRect = CGRect(
        x: petalCenter.x - petalSize / 2,
        y: petalCenter.y - petalSize / 2,
        width: petalSize,
        height: petalSize * 0.85  // Slightly squashed for organic look
      )

      path.addEllipse(in: blobRect)

      // For glow layers, use the flower color
      // For main petals, use white center with colored edge
      let petalColor: Color
      if blur > 0 {
        // Glow layers use flower color
        petalColor = tint ?? flower.color(palette: model.currentPalette)
      } else {
        // Main petals: white center fading to flower color
        petalColor = tint ?? .white
      }

      petalContext.fill(
        path,
        with: .color(petalColor.opacity(opacity))
      )
    }

    // Draw white center for main flower (not for glow layers)
    if blur == 0 && tint == nil {
      let centerSize = flower.petalRadius * 0.6
      let centerRect = CGRect(
        x: center.x + offset.x - centerSize / 2,
        y: center.y + offset.y - centerSize / 2,
        width: centerSize,
        height: centerSize
      )

      // White center with gradient to flower color
      let gradient = Gradient(colors: [
        .white,
        .white.opacity(0.9),
        flower.color(palette: model.currentPalette).opacity(0.7),
      ])

      petalContext.fill(
        Circle().path(in: centerRect),
        with: .radialGradient(
          gradient,
          center: CGPoint(x: centerSize / 2, y: centerSize / 2),
          startRadius: 0,
          endRadius: centerSize / 2
        )
      )
    }
  }

  private func drawSparkle(
    center: CGPoint, flower: Flower, time: TimeInterval, context: GraphicsContext
  ) {
    let sparkleSize: CGFloat = 16 * flower.scale
    let rotation = time * 0.5 + flower.swayPhase

    var sparkleContext = context
    sparkleContext.translateBy(x: center.x, y: center.y)
    sparkleContext.rotate(by: Angle(radians: rotation))

    let sparkleRect = CGRect(
      x: -sparkleSize / 2,
      y: -sparkleSize / 2,
      width: sparkleSize,
      height: sparkleSize
    )

    let gradient = Gradient(colors: [
      .white,
      flower.color(palette: model.currentPalette).opacity(0.8),
      .white.opacity(0),
    ])

    sparkleContext.fill(
      Circle().path(in: sparkleRect),
      with: .radialGradient(
        gradient,
        center: .zero,
        startRadius: 0,
        endRadius: sparkleSize / 2
      )
    )
  }

  private func drawFloatingOrb(center: CGPoint, flower: Flower, context: GraphicsContext) {
    let orbSize: CGFloat = 12 * flower.scale
    let offset = model.chromaticOffset * 0.5

    // Draw chromatic orb layers
    if offset > 0 {
      drawOrbLayer(
        center: center, size: orbSize, offset: CGPoint(x: -offset, y: -offset), color: .red,
        context: context)
      drawOrbLayer(center: center, size: orbSize, offset: .zero, color: .green, context: context)
      drawOrbLayer(
        center: center, size: orbSize, offset: CGPoint(x: offset, y: offset), color: .blue,
        context: context)
    } else {
      drawOrbLayer(
        center: center, size: orbSize, offset: .zero,
        color: flower.color(palette: model.currentPalette), context: context)
    }
  }

  private func drawOrbLayer(
    center: CGPoint, size: CGFloat, offset: CGPoint, color: Color, context: GraphicsContext
  ) {
    var orbContext = context
    orbContext.blendMode = .screen

    let orbRect = CGRect(
      x: center.x + offset.x - size / 2,
      y: center.y + offset.y - size / 2,
      width: size,
      height: size
    )

    orbContext.fill(
      Circle().path(in: orbRect),
      with: .color(color.opacity(0.7))
    )
  }
}

// MARK: - Color Extension

extension Color {
  var hueComponent: Double {
    var hue: CGFloat = 0
    UIColor(self).getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
    return Double(hue)
  }
}

#Preview {
  ContentView()
}
