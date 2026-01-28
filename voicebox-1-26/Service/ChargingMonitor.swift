//
//  ChargingMonitor.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/27/26.
//

import Foundation
import Observation
import UIKit

@Observable
class ChargingMonitor {

    private(set) var isCharging: Bool = false

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateChargingState()
        startMonitoring()
    }

    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateChargingState()
        }
    }

    private func updateChargingState() {
        let state = UIDevice.current.batteryState
        isCharging = (state == .charging || state == .full)
    }
}
