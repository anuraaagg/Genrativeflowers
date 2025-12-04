//
//  ContentView.swift
//  Genrativeflowers
//
//  Created by Anurag Singh on 02/12/25.
//

import Combine
import SwiftUI

struct ContentView: View {
  @StateObject private var appState = AppState()
  @State private var currentFlowerId: UUID? = nil  // Track the flower we just spawned

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // 1. Gradient Background
        LinearGradient(
          colors: [
            Color(red: 0.08, green: 0.10, blue: 0.18),  // Soft deep indigo
            Color(red: 0.04, green: 0.06, blue: 0.12),  // Smooth mid-tone
            Color(red: 0.02, green: 0.03, blue: 0.08),  // Gentle dark blue
            Color(red: 0.01, green: 0.02, blue: 0.05),  // Soft black
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        // 2. Stars Layer
        if appState.showStars {
          GeometryReader { geo in
            StarsView(size: geo.size)
              .ignoresSafeArea()
          }
        }

        // 3. Grain Overlay
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
          Canvas { context, size in
            let time = timeline.date.timeIntervalSinceReferenceDate
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
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)

        // 4. Canvas (Visual Layer)
        GardenCanvas(appState: appState)
          .allowsHitTesting(false)

        // 5. Interaction Layer
        Color.clear
          .contentShape(Rectangle())
          .simultaneousGesture(
            TapGesture()
              .onEnded {
                // Tap handled via DragGesture below for simplicity if needed,
                // but we can keep this empty if we rely on the drag ended logic.
              }
          )
          .simultaneousGesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                let translation = value.translation
                let distance = sqrt(
                  translation.width * translation.width + translation.height * translation.height)

                // If we haven't spawned a flower yet for this gesture, spawn one immediately
                if currentFlowerId == nil && distance < 5 {
                  let newFlowerId = appState.spawnFlower(
                    at: value.startLocation, screenSize: geometry.size)
                  currentFlowerId = newFlowerId
                }

                // If holding (minimal movement), grow the flower we just created
                if distance < 5, let flowerId = currentFlowerId {
                  appState.startGrowing(flowerId: flowerId)
                }
              }
              .onEnded { value in
                appState.stopGrowing()
                currentFlowerId = nil  // Reset for next gesture

                // Handle Drag (Move) vs Swipe (Wind)
                let translation = value.translation
                let distance = sqrt(
                  translation.width * translation.width + translation.height * translation.height)

                if distance > 50 && abs(translation.width) > abs(translation.height) * 1.5 {
                  // Horizontal Swipe -> Wind
                  let windDirection = translation.width > 0 ? 0.0 : Double.pi
                  let windStrength = min(abs(translation.width) / 5, 50.0)

                  withAnimation(.easeInOut(duration: 2.0)) {
                    appState.wind.direction = windDirection
                    appState.wind.strength = windStrength
                  }

                  DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 4.0)) {
                      appState.wind.strength = 5.0
                    }
                  }
                  appState.hapticManager.medium()
                }
              }
          )

        // 6. UI Overlay
        VStack {
          Spacer()
          HStack {
            // Floating Menu Bar (Bottom Center)
            HStack(spacing: 0) {
              // Settings Button
              Button {
                appState.showControlPanel.toggle()
              } label: {
                Image(systemName: "slider.horizontal.3")
                  .font(.system(size: 20))
                  .foregroundStyle(.white.opacity(0.8))
                  .frame(width: 60, height: 50)
              }

              Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.2))

              // Clear All Button
              Button {
                appState.clearAll()
              } label: {
                Image(systemName: "trash")
                  .font(.system(size: 18))
                  .foregroundStyle(.white.opacity(0.8))
                  .frame(width: 60, height: 50)
              }
            }
            .background(
              Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .overlay(
              Capsule()
                .stroke(
                  LinearGradient(
                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ),
                  lineWidth: 1
                )
            )
            .padding(.bottom, 40)
          }
          .frame(maxWidth: .infinity)

          // Flower Count (Bottom Center)
          Text("\(appState.flowers.count) flowers")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.bottom, 10)
        }
      }
    }
    .ignoresSafeArea()
    .sheet(isPresented: $appState.showControlPanel) {
      ControlPanel(appState: appState)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
    .onShake {
      appState.showResetConfirmation = true
      HapticManager.shared.warning()
    }
    .alert("Reset Garden?", isPresented: $appState.showResetConfirmation) {
      Button("Reset", role: .destructive) { appState.resetToDefaults() }
      Button("Cancel", role: .cancel) {}
    }
  }
}

// Shake Detection Helper
extension UIDevice {
  static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
    }
  }
}

struct DeviceShakeViewModifier: ViewModifier {
  let action: () -> Void

  func body(content: Content) -> some View {
    content
      .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) {
        _ in
        action()
      }
  }
}

extension View {
  func onShake(perform action: @escaping () -> Void) -> some View {
    self.modifier(DeviceShakeViewModifier(action: action))
  }
}

#Preview {
  ContentView()
}
