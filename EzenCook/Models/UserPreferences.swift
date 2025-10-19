import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID = UUID()
    var isSubscribed: Bool = false
    var freeWorkoutsCount: Int = 0
    var lastSyncDate: Date = Date()
    
    // Timer settings with default values
    var customWorkTime: Int = 180 // 3:00 in seconds
    var customRestTime: Int = 60  // 1:00 in seconds
    var customRounds: Int = 3
    
    init(isSubscribed: Bool = false, freeWorkoutsCount: Int = 0) {
        self.isSubscribed = isSubscribed
        self.freeWorkoutsCount = freeWorkoutsCount
        self.lastSyncDate = Date()
        // Default timer values are set in the property declarations above
    }
    
    convenience init(freeWorkoutsCount: Int) {
        self.init(isSubscribed: false, freeWorkoutsCount: freeWorkoutsCount)
    }
    
    convenience init(freeWorkoutsCount: Int, customWorkTime: Int, customRestTime: Int, customRounds: Int) {
        self.init(isSubscribed: false, freeWorkoutsCount: freeWorkoutsCount)
        self.customWorkTime = customWorkTime
        self.customRestTime = customRestTime
        self.customRounds = customRounds
    }
}
