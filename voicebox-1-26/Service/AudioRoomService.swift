//
//  AudioRoomService.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
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

    // MARK: - Private

    private var client: StreamVideo?
    private var call: Call?
    private var observationTask: Task<Void, Never>?
    private var isConnecting: Bool = false

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

            // Observe call state changes
            observationTask = Task { await observeCallState(call) }

        } catch {
            self.error = error.localizedDescription
            isConnected = false
        }
    }

    func disconnect() async {
        // Cancel observation first
        observationTask?.cancel()
        observationTask = nil

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
    }

    // MARK: - Private

    /// Force cleanup without checking isConnected - handles crash recovery
    private func forceCleanup() async {
        observationTask?.cancel()
        observationTask = nil

        if let call = call {
            try? await call.leave()
        }

        self.call = nil
        self.client = nil
        isConnected = false
        isLive = false
        participantCount = 0
    }

    @MainActor
    private func observeCallState(_ call: Call) async {
        for await _ in call.state.$participants.values {
            guard !Task.isCancelled else { return }
            participantCount = call.state.participants.count
        }
    }
}
