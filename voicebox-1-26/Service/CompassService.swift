//
//  CompassService.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import Foundation
import CoreLocation
import Observation

@Observable
class CompassService: NSObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    var heading: Int = 0
    var isStarted: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization( )
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = Int(newHeading.magneticHeading)
    }
    
    func start() {
        locationManager.startUpdatingHeading()
        isStarted = true
    }
    
    func stop() {
        locationManager.stopUpdatingHeading()
        isStarted = false
    }
}
