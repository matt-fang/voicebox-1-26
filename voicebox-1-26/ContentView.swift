//
//  ContentView.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//
//  GLOW EFFECT:
//  When someone is detected in front of THIS phone's selfie camera, it glows.
//  Uses a pulsing radial gradient for a warm, inviting effect.
//

import SwiftUI

struct ContentView: View {

    @State var compassService = CompassService()
    @State var markerService = MarkerService()
    var audioRoomService: AudioRoomService
    var presenceService: PresenceService

    @State private var counter = 0

    /// Controls the glow animation pulse
    @State private var glowPulse: Bool = false

    var body: some View {
        ZStack {
            // Glow effect layer - shows when someone is at the other phone
            glowEffectView

            // Main content
            VStack(spacing: 20) {
                audioRoomStatusView

                Divider()

                presenceStatusView

                Divider()

                markersView
                compassView
            }
            .padding()
        }
        .onAppear {
            // Start detecting faces via selfie camera
            presenceService.start()
        }
        .onDisappear {
            presenceService.stop()
        }
    }

    // MARK: - Glow Effect

    /// Full-screen glow effect that appears when someone is in front of the selfie camera
    /// Uses a radial gradient that pulses for a breathing effect
    @ViewBuilder
    private var glowEffectView: some View {
        if presenceService.isSomeonePresent {
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(glowPulse ? 0.6 : 0.4),
                    Color.orange.opacity(glowPulse ? 0.3 : 0.2),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: UIScreen.main.bounds.width
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)
            .onAppear { glowPulse = true }
            .onDisappear { glowPulse = false }
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

    // MARK: - Presence Status

    /// Shows presence detection status (is someone in front of the selfie camera?)
    private var presenceStatusView: some View {
        VStack(spacing: 8) {
            Text("Presence")
                .font(.headline)

            statusIndicator(
                label: presenceService.isSomeonePresent ? "Someone here" : "No one",
                isActive: presenceService.isSomeonePresent,
                activeColor: .yellow
            )

            // Show camera status
            HStack(spacing: 4) {
                Circle()
                    .fill(presenceService.isRunning ? .green : .gray)
                    .frame(width: 6, height: 6)
                Text(presenceService.isRunning ? "Selfie camera active" : "Camera off")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let error = presenceService.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Existing Views

    private var markersView: some View {
        LazyVStack {
            ForEach(markerService.markers) { marker in
                Text("\(marker.name) at \(marker.heading)")
            }
        }
    }

    private var compassView: some View {
        VStack {
            Text(String(compassService.heading))

            Button {
                compassService.isStarted ? compassService.stop() : compassService.start()
            } label: {
                Text("start compass!~")
            }

            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Hello, world!")

            Button {
                print("hello world")
                counter += 1
            } label: {
                Text("press for haptics!")
            }
            .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: counter)
        }
    }
}

#Preview {
    ContentView(
        audioRoomService: AudioRoomService(),
        presenceService: PresenceService()
    )
}
