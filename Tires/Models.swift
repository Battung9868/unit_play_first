//
//  Models.swift
//  Tires
//
//  Created on 04.11.2025.
//

import Foundation
import SwiftUI

// Sales Channel
enum SalesChannel: String, Codable, CaseIterable {
    case shop = "Store"
    case instagram = "Instagram"
    case telegram = "Telegram"
    case online = "Online"
    
    var icon: String {
        switch self {
        case .shop: return "storefront.fill"
        case .instagram: return "camera.fill"
        case .telegram: return "paperplane.fill"
        case .online: return "globe"
        }
    }
    
    var color: Color {
        switch self {
        case .shop: return .blue
        case .instagram: return .pink
        case .telegram: return .cyan
        case .online: return .green
        }
    }
}

// Tire Model
struct Tire: Identifiable, Codable, Hashable {
    var id = UUID()
    var brand: String
    var model: String
    var type: String // Summer, Winter, All-Season
    var width: Int // width in mm
    var profile: Int // profile in %
    var radius: Int // radius in inches
    var quantity: Int
    var price: Double
    
    var displayName: String {
        "\(brand) \(model)"
    }
    
    var parameters: String {
        "\(width)/\(profile) R\(radius)"
    }
}

// Sale Model
struct Sale: Identifiable, Codable {
    var id = UUID()
    var tire: Tire
    var quantity: Int
    var channel: SalesChannel
    var date: Date
    var totalPrice: Double
}

// Analytics Period
enum AnalyticsPeriod: String, CaseIterable {
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

// Tire Analytics Type
enum TireAnalyticsType: String, CaseIterable {
    case brand = "Brand"
    case model = "Model"
    case radius = "Radius"
}

