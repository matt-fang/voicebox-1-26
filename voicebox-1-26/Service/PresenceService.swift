//
//  PresenceService.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//
//  WHAT THIS DOES:
//  Detects if someone is standing in front of the iPhone's selfie (front) camera.
//  Uses Apple's built-in face detection (AVCaptureMetadataOutput) which is:
//  - Hardware-accelerated (low battery usage)
//  - No ML models needed
//  - Works reliably in normal lighting
//
//  HOW IT WORKS:
//  1. Sets up a capture session with the FRONT camera (selfie camera)
//  2. Adds a metadata output that listens for face detection events
//  3. When a face appears/disappears, updates `isSomeonePresent`
//  4. ContentView observes this to show the glow effect
//

import AVFoundation
import Observation

@Observable
class PresenceService: NSObject {

    // MARK: - Public State

    /// True when a face is detected in front of the selfie camera
    private(set) var isSomeonePresent: Bool = false

    /// True when the camera is actively detecting
    private(set) var isRunning: Bool = false

    /// Any error that occurred during setup
    private(set) var error: String?

    // MARK: - Private

    /// The capture session that manages camera input and metadata output
    private let captureSession = AVCaptureSession()

    /// Background queue for camera operations (required by AVFoundation)
    private let sessionQueue = DispatchQueue(label: "presence.session")

    /// Tracks if we've completed initial setup
    private var isConfigured = false

    // MARK: - Lifecycle

    /// Call this to start face detection
    /// Requests camera permission if needed, then starts the capture session
    func start() {
        guard !isRunning else { return }

        // Check/request camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupAndStart()
                } else {
                    DispatchQueue.main.async {
                        self?.error = "Camera permission denied"
                    }
                }
            }
        case .denied, .restricted:
            error = "Camera permission denied. Enable in Settings."
        @unknown default:
            error = "Unknown camera permission status"
        }
    }

    /// Call this to stop face detection
    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.isSomeonePresent = false
            }
        }
    }

    // MARK: - Private Setup

    private func setupAndStart() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Only configure once
            if !self.isConfigured {
                self.configureSession()
            }

            // Start the session
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                    self.error = nil
                }
            }
        }
    }

    /// Sets up the capture session with front camera and face detection
    /// This only runs once, even if start/stop is called multiple times
    private func configureSession() {
        captureSession.beginConfiguration()

        // 1. Add front camera input
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            DispatchQueue.main.async { self.error = "No front camera found" }
            captureSession.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            DispatchQueue.main.async { self.error = "Failed to setup camera: \(error.localizedDescription)" }
            captureSession.commitConfiguration()
            return
        }

        // 2. Add metadata output for face detection
        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            // Set ourselves as the delegate to receive face detection callbacks
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

            // Only detect faces (this is what makes it efficient - hardware accelerated)
            if metadataOutput.availableMetadataObjectTypes.contains(.face) {
                metadataOutput.metadataObjectTypes = [.face]
            }
        }

        // 3. Use low resolution since we only need face detection, not video quality
        if captureSession.canSetSessionPreset(.low) {
            captureSession.sessionPreset = .low
        }

        captureSession.commitConfiguration()
        isConfigured = true
    }
}

// MARK: - Face Detection Delegate

extension PresenceService: AVCaptureMetadataOutputObjectsDelegate {

    /// Called by the system whenever faces appear or disappear from the camera view
    /// This is the heart of the presence detection - very efficient, hardware-accelerated
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        // Check if any of the detected objects are faces
        let faceDetected = metadataObjects.contains { $0.type == .face }

        // Only update if the state actually changed
        if faceDetected != isSomeonePresent {
            isSomeonePresent = faceDetected
        }
    }
}
