//
//  Item.swift
//  SparTime
//
//  Created by Mateusz Ryba on 03/08/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date = Date()
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
