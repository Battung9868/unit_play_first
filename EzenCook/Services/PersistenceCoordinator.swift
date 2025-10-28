import Foundation
import Combine

protocol PersistenceContract {
    func archiveSession(_ workout: WorkoutSession) async throws
    func deleteWorkout(_ workout: WorkoutSession) async throws
    func retrieveChronicles() async throws -> [WorkoutSession]
    func fetchUserSettings() async throws -> UserSettings?
    func saveUserSettings(_ settings: UserSettings) async throws
}

class PersistenceCoordinator: ObservableObject, PersistenceContract {
    private let dataManager: DataManager
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
    }
    
    func archiveSession(_ workout: WorkoutSession) async throws {
        await MainActor.run {
            dataManager.addWorkoutSession(workout)
            print("✅ [PersistenceCoordinator] Workout saved successfully")
        }
    }
    
    func deleteWorkout(_ workout: WorkoutSession) async throws {
        await MainActor.run {
            if let index = dataManager.workoutHistory.firstIndex(where: { $0.id == workout.id }) {
                dataManager.deleteWorkoutSession(at: index)
                print("✅ [PersistenceCoordinator] Workout deleted successfully")
            }
        }
    }
    
    func retrieveChronicles() async throws -> [WorkoutSession] {
        return await MainActor.run {
            let workouts = dataManager.workoutHistory
            print("✅ [PersistenceCoordinator] Fetched \(workouts.count) workouts")
            return workouts
        }
    }
    
    func fetchUserSettings() async throws -> UserSettings? {
        return await MainActor.run {
            print("✅ [PersistenceCoordinator] Fetched user settings")
            return dataManager.userSettings
        }
    }
    
    func saveUserSettings(_ settings: UserSettings) async throws {
        await MainActor.run {
            dataManager.userSettings = settings
            dataManager.saveUserSettings()
            print("✅ [PersistenceCoordinator] User settings saved successfully")
        }
    }
    
    func computeMetrics() async throws -> PerformanceMetrics {
        let workouts = try await retrieveChronicles()
        return PerformanceMetrics(from: workouts)
    }
}

struct PerformanceMetrics {
    let totalWorkouts: Int
    let completedWorkouts: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
    let completionRate: Double
    
    init(from workouts: [WorkoutSession]) {
        self.totalWorkouts = workouts.count
        self.completedWorkouts = workouts.filter { $0.isCompleted }.count
        self.totalDuration = workouts.reduce(0) { $0 + $1.duration }
        self.averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0
        self.completionRate = totalWorkouts > 0 ? Double(completedWorkouts) / Double(totalWorkouts) * 100 : 0
        
        let streaks = Self.calculateStreaks(from: workouts)
        self.currentStreak = streaks.current
        self.longestStreak = streaks.longest
    }
    
    private static func calculateStreaks(from workouts: [WorkoutSession]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let completedWorkouts = workouts.filter { $0.isCompleted }
        let workoutDates = completedWorkouts.map { calendar.startOfDay(for: $0.date) }.removingDuplicates().sorted(by: >)
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        let today = calendar.startOfDay(for: Date())
        
        for (index, date) in workoutDates.enumerated() {
            if index == 0 {
                let daysDifference = calendar.dateComponents([.day], from: date, to: today).day ?? 0
                if daysDifference <= 1 {
                    currentStreak = 1
                    tempStreak = 1
                }
            } else {
                let previousDate = workoutDates[index - 1]
                let daysDifference = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
                
                if daysDifference == 1 {
                    tempStreak += 1
                    if index == 1 && currentStreak > 0 {
                        currentStreak += 1
                    }
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            }
        }
        
        longestStreak = max(longestStreak, tempStreak)
        return (current: currentStreak, longest: longestStreak)
    }
}