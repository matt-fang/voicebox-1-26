//
//  ContentView.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import SwiftUI

struct ContentView: View {

    @State var compassService = CompassService()
    @State var markerService = MarkerService()
    var audioRoomService: AudioRoomService

    @State private var counter = 0

    var body: some View {
        VStack(spacing: 20) {
            audioRoomStatusView

            Divider()

            markersView
            compassView
        }
        .padding()
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
    ContentView(audioRoomService: AudioRoomService())
}
