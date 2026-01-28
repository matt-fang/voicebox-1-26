//
//  Marker.swift
//  voicebox-1-26
//
//  Created by Matthew Fang on 1/26/26.
//

import Foundation

struct Marker: Codable, Identifiable {
    var id: UUID
    var heading: Int
    var name: String
}
