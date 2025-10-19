import Foundation
import SwiftData

@Model
final class WorkoutHistory {
    var id: UUID = UUID()
    var name: String = ""
    var date: Date = Date()
    var duration: TimeInterval = 0
    var rounds: Int = 0
    var isCompleted: Bool = false
    var workoutType: String = ""
    var workTime: Int = 0
    var restTime: Int = 0
    
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

// Extension for convenience methods
extension WorkoutHistory {
    static func from(program: SparProgram, duration: TimeInterval, isCompleted: Bool) -> WorkoutHistory {
        return WorkoutHistory(
            name: program.name,
            duration: duration,
            rounds: program.defaultRounds,
            isCompleted: isCompleted,
            workoutType: program.id,
            workTime: program.workTime,
            restTime: program.restTime
        )
    }
} 