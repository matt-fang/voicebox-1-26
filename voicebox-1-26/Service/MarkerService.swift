//
//  MarkerService.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import Foundation
import Observation

@Observable
class MarkerService {
    var markers: [Marker] = []
    
    init() {
        load()
        markers = [Marker(id: UUID(), heading: 1, name: "Sarah"),
                   Marker(id: UUID(), heading: 180, name: "Atharva")]
    }
    
    func add(_ name: String, at heading: Int) {
        let marker = Marker(id: UUID(), heading: heading, name: name)
        markers.append(marker)
        save()
    }
    
    func remove(id: UUID) {
        markers.removeAll { $0.id == id }
        save()
    }
    
    private func save() {
        guard let data = try? JSONEncoder().encode(markers)
        else {
            return
        }
                
        UserDefaults.standard.set(data, forKey: "markers")
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: "markers"),
              let decoded = try? JSONDecoder().decode(Array<Marker>.self, from: data)
        else {
            markers = []
            return
        }
        markers = decoded
    }
}
