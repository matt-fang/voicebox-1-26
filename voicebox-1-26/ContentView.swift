//
//  ContentView.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//
//  WALLBOX: Full screen yellow glow with pulsing opacity
//

import SwiftUI
import UIKit

struct ContentView: View {

    var audioRoomService: AudioRoomService

    /// Controls the glow animation pulse
    @State private var glowPulse: Bool = false

    var body: some View {
        Color(hex: "FFD24C")
            .ignoresSafeArea()
            .opacity(glowPulse ? 1.0 : 0.5)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)
            .onAppear {
                // Max brightness
                UIScreen.main.brightness = 1.0
                // Start pulsing
                glowPulse = true
            }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

#Preview {
    ContentView(
        audioRoomService: AudioRoomService()
    )
}
