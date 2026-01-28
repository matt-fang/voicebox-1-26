//
//  ContentView.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import SwiftUI
import UIKit

struct ContentView: View {

    @State var compassService = CompassService()
    @State var markerService = MarkerService()
    var audioRoomService: AudioRoomService

    @State private var counter = 0
    @State private var previousBrightness: CGFloat = 0.5

    // Peachy chromatic palette
    private let peachCoral = Color(red: 1.0, green: 0.70, blue: 0.60)       // Vibrant coral peach
    private let peachApricot = Color(red: 1.0, green: 0.78, blue: 0.58)     // Warm apricot
    private let peachBlush = Color(red: 1.0, green: 0.82, blue: 0.72)       // Soft blush
    private let peachGold = Color(red: 1.0, green: 0.85, blue: 0.55)        // Golden peach
    private let warmWhite = Color(red: 1.0, green: 0.95, blue: 0.88)        // Warm white

    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()

            // Animated peachy mesh gradient - only when connected
            if audioRoomService.isConnected {
                PeachyMeshView(
                    amplitude: audioRoomService.micAmplitude,
                    peachCoral: peachCoral,
                    peachApricot: peachApricot,
                    peachBlush: peachBlush,
                    peachGold: peachGold,
                    warmWhite: warmWhite
                )
                .ignoresSafeArea()
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }

            VStack(spacing: 20) {
                audioRoomStatusView
            }
            .padding()
        }
        .ignoresSafeArea()
        .onChange(of: audioRoomService.isConnected) { _, isConnected in
            if isConnected {
                previousBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 1.0
            } else {
                UIScreen.main.brightness = previousBrightness
            }
        }
    }

    // MARK: - Audio Room Status

    private var audioRoomStatusView: some View {
        VStack(spacing: 8) {
            Text("Audio Room")
                .font(.headline)

            HStack(spacing: 16) {
                statusIndicator(
                    label: "Connected",
                    isActive: audioRoomService.isConnected,
                    activeColor: .green
                )

                statusIndicator(
                    label: "Live",
                    isActive: audioRoomService.isLive,
                    activeColor: .red
                )
            }

            Text("\(audioRoomService.participantCount) participant\(audioRoomService.participantCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let error = audioRoomService.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statusIndicator(label: String, isActive: Bool, activeColor: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? activeColor : .gray)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(isActive ? .primary : .secondary)
        }
    }
}

// MARK: - Peachy Mesh View

struct PeachyMeshView: View {
    let amplitude: Float
    let peachCoral: Color
    let peachApricot: Color
    let peachBlush: Color
    let peachGold: Color
    let warmWhite: Color

    @State private var smoothedAmplitude: Float = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let amp = Double(smoothedAmplitude)
                let brightness = 0.4 + amp * 0.6  // Base brightness + amplitude boost
                let maxDim = max(size.width, size.height)

                // Slow organic movement
                let t1 = sin(time * 0.4) * 0.15
                let t2 = cos(time * 0.3) * 0.15
                let t3 = sin(time * 0.5 + 1) * 0.12
                let t4 = cos(time * 0.35 + 2) * 0.12

                // Layer 1: Full screen coral base
                drawFullGradient(
                    context: context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (0.5 + t1),
                        y: size.height * (0.5 + t2)
                    ),
                    radius: maxDim * 1.2,
                    color: peachCoral,
                    opacity: brightness * 0.9
                )

                // Layer 2: Apricot glow
                drawFullGradient(
                    context: context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (0.3 + t3),
                        y: size.height * (0.4 - t1)
                    ),
                    radius: maxDim * 1.0,
                    color: peachApricot,
                    opacity: brightness * 0.8
                )

                // Layer 3: Golden peach
                drawFullGradient(
                    context: context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (0.7 - t2),
                        y: size.height * (0.6 + t4)
                    ),
                    radius: maxDim * 0.9,
                    color: peachGold,
                    opacity: brightness * 0.7
                )

                // Layer 4: Blush accent
                drawFullGradient(
                    context: context,
                    size: size,
                    center: CGPoint(
                        x: size.width * (0.5 - t4),
                        y: size.height * (0.7 + t3)
                    ),
                    radius: maxDim * 0.85,
                    color: peachBlush,
                    opacity: brightness * 0.75
                )

                // Layer 5: Bright center when speaking
                drawFullGradient(
                    context: context,
                    size: size,
                    center: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                    radius: maxDim * (0.6 + amp * 0.4),
                    color: warmWhite,
                    opacity: amp * 0.6
                )
            }
        }
        .onChange(of: amplitude) { _, newValue in
            withAnimation(.spring(response: 0.12, dampingFraction: 0.8)) {
                smoothedAmplitude = newValue
            }
        }
        .onAppear {
            smoothedAmplitude = amplitude
        }
    }

    private func drawFullGradient(
        context: GraphicsContext,
        size: CGSize,
        center: CGPoint,
        radius: Double,
        color: Color,
        opacity: Double
    ) {
        let gradient = Gradient(colors: [
            color.opacity(min(opacity, 1.0)),
            color.opacity(min(opacity * 0.7, 1.0)),
            color.opacity(min(opacity * 0.3, 1.0)),
            color.opacity(0)
        ])

        context.fill(
            Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )),
            with: .radialGradient(
                gradient,
                center: center,
                startRadius: 0,
                endRadius: radius
            )
        )
    }
}

#Preview {
    ContentView(audioRoomService: AudioRoomService())
}
