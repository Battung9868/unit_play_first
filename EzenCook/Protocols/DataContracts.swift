import Foundation

protocol WorkoutRepositoryProtocol {
    func save(_ workout: WorkoutSession) async throws
    func delete(_ workout: WorkoutSession) async throws
    func fetchAll() async throws -> [WorkoutSession]
    func fetchCompleted() async throws -> [WorkoutSession]
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [WorkoutSession]
}

protocol UserSettingsRepositoryProtocol {
    func save(_ settings: UserSettings) async throws
    func fetch() async throws -> UserSettings?
    func update(_ settings: UserSettings) async throws
}

protocol SubscriptionRepositoryProtocol {
    func save(_ status: SubscriptionStatus) async throws
    func fetch() async throws -> SubscriptionStatus?
    func update(_ status: SubscriptionStatus) async throws
}

protocol WorkoutServiceProtocol {
    func createWorkout(name: String, workTime: Int, restTime: Int, rounds: Int) -> WorkoutSession
    func completeWorkout(_ workout: WorkoutSession, duration: TimeInterval) async throws
    func cancelWorkout(_ workout: WorkoutSession) async throws
    func getWorkoutStatistics() async throws -> PerformanceMetrics
}

protocol UserPreferencesServiceProtocol {
    func updateTimerSettings(workTime: Int, restTime: Int, rounds: Int) async throws
    func getTimerSettings() async throws -> (workTime: Int, restTime: Int, rounds: Int)
    func updateSubscriptionStatus(_ isSubscribed: Bool) async throws
    func getSubscriptionStatus() async throws -> Bool
}

protocol AnalyticsServiceProtocol {
    func trackWorkoutStart(_ workout: WorkoutSession)
    func trackWorkoutComplete(_ workout: WorkoutSession)
    func trackWorkoutCancel(_ workout: WorkoutSession)
    func trackAppOpen()
    func trackFeatureUsage(_ feature: String)
}

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleWorkoutReminder(at date: Date)
    func cancelWorkoutReminder()
    func scheduleDailyReminder(at hour: Int, minute: Int)
    func cancelDailyReminder()
}

