import SwiftUI
import Combine

// MARK: - Simple Color Palette
struct ColorPalette {
    let colors: [Color]
}

// MARK: - Flower Model
struct Flower: Identifiable {
    let id = UUID()
    var baseX: CGFloat
    var petalCount: Int
    var petalRadius: CGFloat
    var scale: CGFloat
    var swayPhase: Double
    var hue: Double

    func color(palette: ColorPalette) -> Color {
        // Use hue to pick a color from palette
        if palette.colors.isEmpty { return Color(hue: hue, saturation: 0.8, brightness: 1.0) }
        let index = Int((hue * Double(palette.colors.count)).truncatingRemainder(dividingBy: Double(palette.colors.count)))
        return palette.colors[max(0, min(index, palette.colors.count - 1))]
    }

    func glowPulse(at time: TimeInterval) -> Double {
        let speed = 1.0 + (Double(scale) * 0.5)
        return (sin(time * speed + swayPhase) + 1) / 2 // 0..1
    }

    func currentHeadPosition(time: TimeInterval, windStrength: CGFloat, windDirection: CGFloat) -> CGPoint {
        let sway = sin(time * 0.8 + swayPhase) * Double(windStrength) * 10.0
        let x = baseX + CGFloat(sway) * cos(CGFloat(windDirection))
        let y = CGFloat(300 - (scale * 120)) + CGFloat(sin(time * 0.6 + swayPhase)) * 6
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Garden Model
struct GardenModel {
    // Scene controls
    var showStars: Bool = true
    var currentPaletteIndex: Int = 0
    var palettes: [ColorPalette] = [
        ColorPalette(colors: [.pink, .purple, .blue, .cyan]),
        ColorPalette(colors: [.orange, .yellow, .red]),
        ColorPalette(colors: [.mint, .teal, .blue])
    ]

    var globalScale: CGFloat = 1.0
    var bloomIntensity: Double = 1.0
    var chromaticOffset: CGFloat = 1.0

    var windStrength: CGFloat = 0.6
    var windDirection: CGFloat = .pi / 8

    var flowers: [Flower] = []

    // Time
    var currentTime: TimeInterval = 0

    var currentPalette: ColorPalette { palettes[currentPaletteIndex % palettes.count] }

    mutating func updateTime(_ t: TimeInterval) { currentTime = t }

    mutating func cyclePalette() {
        currentPaletteIndex = (currentPaletteIndex + 1) % max(1, palettes.count)
    }

    mutating func addFlower(at point: CGPoint) {
        // Create a flower whose baseX is the tap x; other params randomized
        var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))
        let petalCount = Int(rng.nextInt(in: 6...12))
        let petalRadius = rng.nextCGFloat(in: 20...40)
        let scale = rng.nextCGFloat(in: 0.8...1.4)
        let sway = rng.nextDouble(in: 0...(.pi * 2))
        let hue = rng.nextDouble(in: 0...1)

        let flower = Flower(
            baseX: point.x,
            petalCount: petalCount,
            petalRadius: petalRadius,
            scale: scale,
            swayPhase: sway,
            hue: hue
        )
        flowers.append(flower)
    }
}

// MARK: - Haptics
final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    func light() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Deterministic Random
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextDouble(in range: ClosedRange<Double>) -> Double {
        let v = Double(next()) / Double(UInt64.max)
        return range.lowerBound + (range.upperBound - range.lowerBound) * v
    }

    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat(nextDouble(in: Double(range.lowerBound)...Double(range.upperBound)))
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let v = next() % UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(v)
    }
}

// MARK: - Stars View
struct StarsView: View {
    let size: CGSize
    var body: some View {
        Canvas { context, canvasSize in
            var rng = SeededRandom(seed: 42)
            let count = Int((size.width * size.height) / 8000)
            for _ in 0..<(max(50, count)) {
                let x = rng.nextCGFloat(in: 0...canvasSize.width)
                let y = rng.nextCGFloat(in: 0...canvasSize.height)
                let r = rng.nextCGFloat(in: 0.5...1.8)
                let rect = CGRect(x: x, y: y, width: r, height: r)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(0.8)))
            }
        }
    }
}

// MARK: - Control Panel (minimal placeholder)
struct ControlPanel: View {
    @State var model: GardenModel
    let canvasSize: CGSize

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 12) {
                Button("Palette") { model.cyclePalette(); HapticManager.shared.success() }
                Toggle("Stars", isOn: Binding(get: { model.showStars }, set: { model.showStars = $0 }))
                    .labelsHidden()
            }
            HStack(spacing: 12) {
                Text("Wind")
                Slider(value: Binding(get: { Double(model.windStrength) }, set: { model.windStrength = CGFloat($0) }), in: 0...2)
                    .frame(width: 120)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
