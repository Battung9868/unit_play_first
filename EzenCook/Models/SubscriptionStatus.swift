import Foundation
import SwiftData

@Model
final class SubscriptionStatus {
    var isSubscribed: Bool?
    var lastUpdated: Date?
    
    init(isSubscribed: Bool = false, lastUpdated: Date = Date()) {
        self.isSubscribed = isSubscribed
        self.lastUpdated = lastUpdated
    }
} 