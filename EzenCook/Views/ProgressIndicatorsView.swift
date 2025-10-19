import SwiftUI
import Charts
import SwiftData

// MARK: - Main View
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @Query(sort: \WorkoutHistory.date, order: .reverse) private var workouts: [WorkoutHistory]
    @State private var showAllWorkouts = false
    
    var displayedWorkouts: [WorkoutHistory] {
        if showAllWorkouts {
            return workouts
        } else {
            return Array(workouts.prefix(5))
        }
    }
    
    // Computed properties
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        
        // Get completed workouts sorted by date
        let sortedWorkouts = workouts
            .filter { $0.isCompleted }  // Only count completed workouts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
            .removingDuplicates()  // Remove duplicate dates
        
        // If no workouts, return 0
        guard !sortedWorkouts.isEmpty else { return 0 }
        
        // Check if the most recent workout is from today or yesterday
        let mostRecentDate = sortedWorkouts[0]
        let dayDifference = calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0
        
        // If the most recent workout is older than yesterday, no current streak
        guard dayDifference <= 1 else { return 0 }
        
        // Start counting from the most recent workout
        var currentDate = mostRecentDate
        streak = 1
        
        // Check consecutive days
        for date in sortedWorkouts.dropFirst() {
            let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if date == expectedPreviousDay {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }
        
        return streak
    }
    
    var longestStreak: Int {
        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        // Get completed workouts sorted by date (oldest to newest)
        let sortedWorkouts = workouts
            .filter { $0.isCompleted }  // Only count completed workouts
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
            .removingDuplicates()
        
        // If no workouts, return 0
        guard !sortedWorkouts.isEmpty else { return 0 }
        
        // Calculate streaks
        for date in sortedWorkouts {
            if let last = lastDate {
                let dayDifference = calendar.dateComponents([.day], from: last, to: date).day ?? 0
                if dayDifference == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else {
                    // Break in streak
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                // First workout
                currentStreak = 1
            }
            lastDate = date
        }
        
        // Check one final time to catch the last streak
        maxStreak = max(maxStreak, currentStreak)
        
        // Compare with current streak
        let currentStreakValue = self.currentStreak
        return max(maxStreak, currentStreakValue)
    }
    
    var totalTimeWorkedOut: TimeInterval {
        workouts.reduce(0) { total, workout in
            total + workout.duration
        }
    }
    
    var completionRate: Double {
        let completed = workouts.filter { $0.isCompleted }.count
        return workouts.isEmpty ? 0 : Double(completed) / Double(workouts.count) * 100
    }
    
    var averageRoundDuration: TimeInterval {
        var totalRoundTime: TimeInterval = 0
        var totalRounds = 0
        
        for workout in workouts {
            // For completed workouts, use theoretical time per round
            if workout.isCompleted {
                let roundTime = Double(workout.workTime)
                let restTime = Double(workout.restTime)
                
                if workout.rounds == 1 {
                    // Single round - no rest
                    totalRoundTime += roundTime
                    totalRounds += 1
                } else if workout.restTime == 0 {
                    // Multiple rounds without rest
                    totalRoundTime += roundTime * Double(workout.rounds)
                    totalRounds += workout.rounds
                } else {
                    // Multiple rounds with rest - don't count rest after last round
                    totalRoundTime += (roundTime + restTime) * Double(workout.rounds - 1) + roundTime
                    totalRounds += workout.rounds
                }
            }
            // For interrupted workouts, only count completed rounds
            else if workout.rounds > 1 {  // More than 1 means at least one round was completed
                let roundTime = Double(workout.workTime)
                let restTime = Double(workout.restTime)
                let completedRounds = workout.rounds - 1  // Subtract 1 as the last round wasn't completed
                
                if workout.restTime == 0 {
                    // Multiple rounds without rest
                    totalRoundTime += roundTime * Double(completedRounds)
                    totalRounds += completedRounds
                } else {
                    // Multiple rounds with rest
                    totalRoundTime += (roundTime + restTime) * Double(completedRounds - 1) + roundTime
                    totalRounds += completedRounds
                }
            }
        }
        
        return totalRounds == 0 ? 0 : totalRoundTime / Double(totalRounds)
    }
    
    var mostActiveDay: String {
        let calendar = Calendar.current
        var dayCount: [Int: Int] = [:] // [weekday: count]
        
        // Count workouts for each day of the week
        for workout in workouts where workout.isCompleted {
            let weekday = calendar.component(.weekday, from: workout.date)
            dayCount[weekday, default: 0] += 1
        }
        
        // Find the day with most workouts
        if let mostActive = dayCount.max(by: { $0.value < $1.value }) {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US")
            return dateFormatter.weekdaySymbols[mostActive.key - 1]
        }
        
        return "N/A"
    }
    
    var weeklyWorkoutData: [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create a dictionary to store total duration for each day
        var dailyDurations: [Date: TimeInterval] = [:]
        
        // Get the date range
        let dates = (-6...0).map { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)!
        }
        
        // Calculate total duration for each day using actual duration
        for workout in workouts {
            let workoutDay = calendar.startOfDay(for: workout.date)
            if dates.contains(workoutDay) {
                dailyDurations[workoutDay, default: 0] += workout.duration
            }
        }
        
        // Create the final array with all days, using 0 duration for days without workouts
        return dates.map { date in
            (date: date, duration: dailyDurations[date] ?? 0)
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutHistory) {
        modelContext.delete(workout)
        do {
            try modelContext.save()
            print("✅ [History] Workout deleted from history")
            
            // Queue the CloudKit export
            CloudKitSyncManager.shared.queueExportRequest {
                do {
                    try modelContext.save()
                    print("✅ [CloudKit] Deletion exported to CloudKit")
                } catch {
                    print("❌ [CloudKit] Failed to export deletion: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ [History] Failed to delete workout: \(error.localizedDescription)")
        }
    }
    
    func deleteWorkout(at indexSet: IndexSet) {
        for index in indexSet {
            deleteWorkout(displayedWorkouts[index])
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("View", selection: $selectedTab) {
                    Text("History")
                        .foregroundColor(Color("PrimaryText"))
                        .tag(0)
                    Text("Stats")
                        .foregroundColor(Color("PrimaryText"))
                        .tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color("Background"))
                
                // Content based on selection
                if selectedTab == 0 {
                    // History Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Top Section
                            StreakView(currentStreak: currentStreak, longestStreak: longestStreak)
                            
                            // Progress Indicators
                            ProgressIndicatorsView(
                                totalTime: totalTimeWorkedOut,
                                completionRate: completionRate
                            )
                            
                            // Weekly Graph
                            WeeklyGraphView(data: weeklyWorkoutData)
                            
                            // Workout Stats
                            WorkoutStatsView(
                                averageDuration: averageRoundDuration,
                                mostActiveDay: mostActiveDay
                            )
                            
                            // Workout History List
                            WorkoutHistoryListView(
                                workouts: displayedWorkouts,
                                totalWorkouts: workouts.count,
                                showAllWorkouts: $showAllWorkouts,
                                onDelete: deleteWorkout
                            )
                        }
                        .padding()
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .speed(0.8), // Slow down the overall animation
                            value: displayedWorkouts
                        )
                    }
                    .background(Color("Background"))
                } else {
                    // Stats Content
                    StatsView(workouts: workouts)
                        .background(Color("Background"))
                }
            }
            .navigationTitle("My Sushi Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color("SecondaryText"),
                                        Color("SecondaryText").opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .background(Color("Background"))
        }
    }
}

// MARK: - Component Views
struct StreakView: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Current Session Streak")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
            
            VStack {
                Text("\(longestStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Longest Session Streak")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct ProgressIndicatorsView: View {
    let totalTime: TimeInterval
    let completionRate: Double
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text(formatDuration(totalTime))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Total Sushi Time")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
            
            VStack {
                Text("\(Int(completionRate))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Completion Rate")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

struct WeeklyGraphView: View {
    let data: [(date: Date, duration: TimeInterval)]
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7-Day Activity")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            
            chartContent
        }
        .padding()
        .background(Color("Border"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
        )
    }
    
    private var chartContent: some View {
        let maxDuration = data.map { $0.duration / 60 }.max() ?? 0
        let yAxisMax = ceil(max(maxDuration + 1, 3)) // At least 3 minutes, or higher if needed
        
        return Chart(data, id: \.date) { item in
            AreaMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Duration", item.duration / 60)
            )
            .foregroundStyle(areaGradient)
            .interpolationMethod(.monotone)
            
            LineMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Duration", item.duration / 60)
            )
            .foregroundStyle(Color("Accent"))
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.monotone)
            
            PointMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Duration", item.duration / 60)
            )
            .foregroundStyle(Color("Accent"))
            .symbolSize(40)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(dayFormatter.string(from: date))
                            .foregroundStyle(Color("SecondaryText"))
                            .frame(width: 30, alignment: .center)
                            .fixedSize()
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(preset: .extended, values: .stride(by: 1)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text("\(Int(minutes))m")
                            .foregroundStyle(Color("SecondaryText"))
                    }
                }
            }
        }
        .chartYScale(domain: 0...yAxisMax)
        .chartPlotStyle { plotArea in
            plotArea
                .frame(height: 200)
                .background(Color("Border"))
        }
    }
    
    private var areaGradient: some ShapeStyle {
        LinearGradient(
            colors: [
                Color("Accent").opacity(0.3),
                Color("Accent").opacity(0.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct WorkoutStatsView: View {
    let averageDuration: TimeInterval
    let mostActiveDay: String
    
    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text(formatDuration(averageDuration))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Avg. Roll Duration")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
            
            VStack {
                Text(mostActiveDay)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("Accent"))
                Text("Most Active Cooking Day")
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("Border"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

struct WorkoutHistoryListView: View {
    let workouts: [WorkoutHistory]
    let totalWorkouts: Int
    @Binding var showAllWorkouts: Bool
    let onDelete: (WorkoutHistory) -> Void
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutHistory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            
            ForEach(Array(workouts.enumerated()), id: \.element.id) { index, workout in
                WorkoutHistoryItemView(workout: workout) {
                    workoutToDelete = workout
                    showingDeleteAlert = true
                }
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8)
                            .combined(with: .opacity)
                            .combined(with: .move(edge: .top))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.1)),
                        removal: .opacity
                            .combined(with: .scale(scale: 0.95))
                            .animation(.easeOut(duration: 0.15).delay(Double(index) * 0.03))
                    )
                )
            }
            
            if totalWorkouts > 5 {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(showAllWorkouts ? 0.3 : 0)) {
                        showAllWorkouts.toggle()
                    }
                }) {
                    Text(showAllWorkouts ? "Show Less" : "Show More")
                        .font(.headline)
                        .foregroundColor(Color("ButtonText"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color("Button").opacity(1.2),
                                    Color("Button"),
                                    Color("Button").opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(
                            color: Color("Button").opacity(0.3),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                }
                .padding(.top, 8)
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .move(edge: .bottom))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8)),
                        removal: .opacity
                            .animation(.easeOut(duration: 0.2).delay(0.2))
                    )
                )
            }
        }
        .padding()
        .background(Color("Border"))
        .cornerRadius(12)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: workouts.count)
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    onDelete(workout)
                }
            }
        } message: {
            if let workout = workoutToDelete {
                Text("Are you sure you want to delete '\(workout.name)'? This action cannot be undone.")
            }
        }
    }
}

struct WorkoutHistoryItemView: View {
    let workout: WorkoutHistory
    let onDelete: () -> Void
    
    private var theoreticalDuration: TimeInterval {
        // Calculate the pure workout time without transitions
        let roundTime = Double(workout.workTime)
        let restTime = Double(workout.restTime)
        
        if workout.rounds == 1 {
            return roundTime
        } else if workout.restTime == 0 {
            return roundTime * Double(workout.rounds)
        } else {
            return (roundTime + restTime) * Double(workout.rounds - 1) + roundTime
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                HStack {
                    Text(formatDate(workout.date))
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    if workout.isCompleted {
                        Text("•")
                            .foregroundColor(Color("SecondaryText"))
                        
                        Text("\(workout.rounds) rolls")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                        
                        Text("•")
                            .foregroundColor(Color("SecondaryText"))
                        
                        Text(formatDuration(theoreticalDuration))
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    } else {
                        Text("•")
                            .foregroundColor(Color("SecondaryText"))
                        
                        Text("Interrupted")
                            .font(.subheadline)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundColor(.red)
                    .opacity(0.8)
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(workout.isCompleted ? Color.green : Color.red, lineWidth: 1)
        )
        .shadow(
            color: (workout.isCompleted ? Color.green : Color.red).opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

struct StatsView: View {
    let workouts: [WorkoutHistory]
    @State private var showingAllWorkouts = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Detailed Workout Stats
                DetailedWorkoutStatsView(
                    workouts: workouts,
                    showingAllWorkouts: $showingAllWorkouts
                )
            }
            .padding()
        }
    }
}

struct DetailedWorkoutStatsView: View {
    let workouts: [WorkoutHistory]
    @Binding var showingAllWorkouts: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var workoutToDelete: WorkoutHistory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sushi Session Statistics")
                .font(.headline)
                .foregroundColor(Color("PrimaryText"))
            
            LazyVStack(spacing: 12) {
                ForEach(workouts.prefix(showingAllWorkouts ? workouts.count : 5), id: \.id) { workout in
                    WorkoutStatsCard(workout: workout, onDelete: {
                        workoutToDelete = workout
                    })
                }
            }
            
            if workouts.count > 5 {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(showingAllWorkouts ? 0.3 : 0)) {
                        showingAllWorkouts.toggle()
                    }
                }) {
                    Text(showingAllWorkouts ? "Show Less" : "Show More")
                        .font(.headline)
                        .foregroundColor(Color("ButtonText"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color("Button").opacity(1.2),
                                    Color("Button"),
                                    Color("Button").opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(
                            color: Color("Button").opacity(0.3),
                            radius: 5,
                            x: 0,
                            y: 2
                        )
                }
                .padding(.top, 8)
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .move(edge: .bottom))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8)),
                        removal: .opacity
                            .animation(.easeOut(duration: 0.2).delay(0.2))
                    )
                )
            }
        }
        .padding()
        .background(Color("Border"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("SecondaryText").opacity(0.2), lineWidth: 1)
        )
        .alert("Delete Workout", isPresented: .constant(workoutToDelete != nil)) {
            Button("Cancel", role: .cancel) {
                workoutToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let workout = workoutToDelete {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        deleteWorkout(workout)
                    }
                }
                workoutToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutHistory) {
        modelContext.delete(workout)
        try? modelContext.save()
    }
}

struct WorkoutStatsCard: View {
    let workout: WorkoutHistory
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Workout name and date
            HStack {
                Text("Sushi Session")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text(formatDate(workout.date))
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            
            // Stats grid
            HStack(spacing: 16) {
                StatItem(title: "Roll Time", value: formatTime(workout.workTime))
                StatItem(title: "Rest Time", value: workout.restTime == 0 ? "No Rest" : formatTime(workout.restTime))
                StatItem(title: "Rolls", value: "\(workout.rounds)")
            }
            
            // Completion status and delete button
            HStack {
                Circle()
                    .fill(workout.isCompleted ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(workout.isCompleted ? "Completed" : "Interrupted")
                    .font(.caption)
                    .foregroundColor(workout.isCompleted ? Color.green : Color.red)
                
                Spacer()
                
                Text(formatDuration(workout.duration))
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                    .onAppear {
                        print("🔍 [History] Workout duration: \(workout.duration)s (\(Int(workout.duration/60)):\(String(format: "%02d", Int(workout.duration.truncatingRemainder(dividingBy: 60))))")
                        print("🔍 [History] Raw duration value: \(workout.duration)")
                    }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color("Background"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(workout.isCompleted ? Color.green : Color.red, lineWidth: 1)
        )
        .shadow(
            color: (workout.isCompleted ? Color.green : Color.red).opacity(0.2),
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", remainingSeconds))"
        } else {
            return "\(remainingSeconds) sec"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("PrimaryText"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



// Add extension to remove duplicates from sorted array
extension Array where Element: Equatable {
    func removingDuplicates() -> [Element] {
        var result = [Element]()
        for value in self {
            if !result.contains(value) {
                result.append(value)
            }
        }
        return result
    }
}

#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
} 