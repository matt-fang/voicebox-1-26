//
//  voicebox_1_26App.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//
//  WALLBOX: Full screen yellow glow
//  Audio room kept for future use
//

import SwiftUI
import UIKit

@main
struct voicebox_1_26App: App {

    @State private var audioRoomService = AudioRoomService()
    @State private var chargingMonitor = ChargingMonitor()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(
                audioRoomService: audioRoomService
            )
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                handleScenePhase(newPhase)
            }
            .onChange(of: chargingMonitor.isCharging) { _, isCharging in
                handleChargingChange(isCharging)
            }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Only connect if charging
            if chargingMonitor.isCharging {
                Task { await audioRoomService.connect() }
            }
        case .background:
            Task { await audioRoomService.disconnect() }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func handleChargingChange(_ isCharging: Bool) {
        // Only act if app is in foreground
        guard scenePhase == .active else { return }

        if isCharging {
            Task { await audioRoomService.connect() }
        } else {
            Task { await audioRoomService.disconnect() }
        }
    }
}
