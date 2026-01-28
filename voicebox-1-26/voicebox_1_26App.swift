//
//  voicebox_1_26App.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import SwiftUI

@main
struct voicebox_1_26App: App {

    @State private var audioRoomService = AudioRoomService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(audioRoomService: audioRoomService)
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    handleScenePhase(newPhase)
                }
        }
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task { await audioRoomService.connect() }
        case .background:
            Task { await audioRoomService.disconnect() }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
