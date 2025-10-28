import Foundation
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var userSettings: UserSettings
    @Published var workoutHistory: [WorkoutSession] = []
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "EzenCookUserSettings"
    private let historyKey = "EzenCookWorkoutHistory"
    
    private init() {
        self.userSettings = Self.loadUserSettings()
        self.workoutHistory = Self.loadWorkoutHistory()
    }
    
    private static func loadUserSettings() -> UserSettings {
        if let data = UserDefaults.standard.data(forKey: "EzenCookUserSettings"),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return UserSettings()
    }
    
    private static func loadWorkoutHistory() -> [WorkoutSession] {
        if let data = UserDefaults.standard.data(forKey: "EzenCookWorkoutHistory"),
           let history = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            return history
        }
        return []
    }
    
    func saveUserSettings() {
        if let data = try? JSONEncoder().encode(userSettings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }
    
    func saveWorkoutHistory() {
        if let data = try? JSONEncoder().encode(workoutHistory) {
            userDefaults.set(data, forKey: historyKey)
        }
    }
    
    func addWorkoutSession(_ session: WorkoutSession) {
        workoutHistory.insert(session, at: 0)
        saveWorkoutHistory()
    }
    
    func deleteWorkoutSession(at index: Int) {
        guard index < workoutHistory.count else { return }
        workoutHistory.remove(at: index)
        saveWorkoutHistory()
    }
    
    func clearAllData() {
        workoutHistory.removeAll()
        userSettings = UserSettings()
        saveWorkoutHistory()
        saveUserSettings()
    }
}

struct UserSettings: Codable {
    var customWorkTime: Int = 5
    var customRestTime: Int = 5
    var customRounds: Int = 3
    var freeWorkoutsCount: Int = 0
    var isSubscribed: Bool = false
    var lastSyncDate: Date = Date()
    
    init() {}
}

struct SubscriptionStatus: Codable {
    var isSubscribed: Bool = false
    var lastUpdated: Date = Date()
    
    init() {}
}

struct WorkoutSession: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let date: Date
    let duration: TimeInterval
    let rounds: Int
    let isCompleted: Bool
    let workoutType: String
    let workTime: Int
    let restTime: Int
    
    init(
        name: String,
        date: Date = Date(),
        duration: TimeInterval,
        rounds: Int,
        isCompleted: Bool,
        workoutType: String,
        workTime: Int,
        restTime: Int
    ) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.duration = duration
        self.rounds = rounds
        self.isCompleted = isCompleted
        self.workoutType = workoutType
        self.workTime = workTime
        self.restTime = restTime
    }
}
