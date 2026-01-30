//
//  AudioRoomService.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//
//  WHAT THIS DOES:
//  Manages the real-time audio connection between phones using GetStream.
//  Now also handles presence detection broadcasting:
//  - Sends local presence state (is someone in front of THIS phone?)
//  - Receives remote presence state (is someone in front of OTHER phone?)
//
//  PRESENCE FLOW:
//  1. PresenceService detects face → calls sendPresenceUpdate(true)
//  2. This sends a custom event over GetStream to all participants
//  3. Other phone receives event → updates `remotePresenceDetected`
//  4. ContentView observes `remotePresenceDetected` → shows glow effect
//

import Foundation
import Observation
import StreamVideo
internal import Combine

@Observable
class AudioRoomService {

    // MARK: - Configuration

    var userId: String = "2"
    var token: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMiJ9.jr0NBXqo_MIaqzV4K-MfONAZGKsUo9hZzfnrhxA4zdU"

    private let apiKey: String = "6yks7w9qurxz"
    private let callId: String = "kk1gLiCOzwYDUhMq98Oqk"

    // MARK: - State

    private(set) var isConnected: Bool = false
    private(set) var isLive: Bool = false
    private(set) var participantCount: Int = 0
    private(set) var error: String?

    // MARK: - Presence State

    /// True when someone is detected in front of the OTHER phone
    /// ContentView observes this to show the glow effect
    private(set) var remotePresenceDetected: Bool = false

    // MARK: - Private

    private var client: StreamVideo?
    private var call: Call?
    private var observationTask: Task<Void, Never>?
    private var presenceObservationTask: Task<Void, Never>?
    private var isConnecting: Bool = false

    /// Key used in custom events to identify presence data
    private let presenceEventKey = "presence_detected"

    // MARK: - Lifecycle

    func connect() async {
        // Prevent concurrent connect attempts and don't reconnect if already connected
        guard !isConnected && !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }

        // Force cleanup any existing state (handles crash recovery / stale connections)
        await forceCleanup()

        do {
            // Create user
            let user = User(
                id: userId,
                name: userId
            )

            // Initialize Stream Video client
            let client = StreamVideo(
                apiKey: apiKey,
                user: user,
                token: .init(stringLiteral: token)
            )
            self.client = client

            // Create call - use "default" type, not "audio_room"
            // audio_room has backstage mode which blocks non-creators from joining
            // until goLive() is called. "default" allows anyone to join immediately.
            let call = client.call(callType: "default", callId: callId)
            self.call = call

            // Join call (creates if doesn't exist)
            try await call.join(create: true)

            isConnected = true
            isLive = true
            error = nil

            // Observe call state changes (participant count)
            observationTask = Task { await observeCallState(call) }

            // Observe custom events (presence updates from other phones)
            presenceObservationTask = Task { await observePresenceEvents(call) }

        } catch {
            self.error = error.localizedDescription
            isConnected = false
        }
    }

    // MARK: - Presence Broadcasting

    /// Send presence state to other phones in the call
    /// Called by PresenceService whenever someone appears/disappears from camera
    func sendPresenceUpdate(_ isPresent: Bool) {
        guard isConnected, let call = call else { return }

        Task {
            do {
                // Send custom event with presence data
                // All other participants in the call will receive this
                try await call.sendCustomEvent([presenceEventKey: .bool(isPresent)])
            } catch {
                // Don't surface this error to UI - presence is best-effort
                print("Failed to send presence update: \(error)")
            }
        }
    }

    func disconnect() async {
        // Cancel all observation tasks first
        observationTask?.cancel()
        observationTask = nil
        presenceObservationTask?.cancel()
        presenceObservationTask = nil

        guard isConnected, let call = call else { return }

        do {
            try await call.leave()
        } catch {
            self.error = error.localizedDescription
        }

        self.call = nil
        self.client = nil
        isConnected = false
        isLive = false
        participantCount = 0
        remotePresenceDetected = false
    }

    // MARK: - Private

    /// Force cleanup without checking isConnected - handles crash recovery
    private func forceCleanup() async {
        observationTask?.cancel()
        observationTask = nil
        presenceObservationTask?.cancel()
        presenceObservationTask = nil

        if let call = call {
            try? await call.leave()
        }

        self.call = nil
        self.client = nil
        isConnected = false
        isLive = false
        participantCount = 0
        remotePresenceDetected = false
    }

    @MainActor
    private func observeCallState(_ call: Call) async {
        for await _ in call.state.$participants.values {
            guard !Task.isCancelled else { return }
            participantCount = call.state.participants.count
        }
    }

    /// Listen for custom events from other participants
    /// When another phone sends a presence update, we receive it here
    @MainActor
    private func observePresenceEvents(_ call: Call) async {
        // Subscribe to custom events on this call
        for await event in call.subscribe(for: CustomVideoEvent.self) {
            guard !Task.isCancelled else { return }

            // Extract presence data from the custom event
            // The event contains the data we sent via sendCustomEvent()
            if let presenceValue = event.custom[presenceEventKey] {
                // Handle different possible value types from the API
                switch presenceValue {
                case .bool(let isPresent):
                    remotePresenceDetected = isPresent
                case .string(let str):
                    // Fallback: some APIs send booleans as strings
                    remotePresenceDetected = (str == "true" || str == "1")
                default:
                    break
                }
            }
        }
    }
}
