import SwiftUI

struct HistoryView: View {
    
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataManager: DataManager
    
    
    @State private var selectedTabIndex = 0
    @State private var showAllWorkouts = false
    
    private var allWorkouts: [WorkoutSession] {
        dataManager.workoutHistory
    }
    
    
    var displayedWorkouts: [WorkoutSession] {
        if showAllWorkouts {
            return Array(allWorkouts)
        } else {
            return Array(allWorkouts.prefix(5))
        }
    }
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        
        let sortedWorkouts = allWorkouts
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted(by: >)
            .removingDuplicates()
        
        guard !sortedWorkouts.isEmpty else { return 0 }
        
        let mostRecentDate = sortedWorkouts[0]
        let dayDifference = calendar.dateComponents([.day], from: mostRecentDate, to: today).day ?? 0
        
        guard dayDifference <= 1 else { return 0 }
        
        var currentDate = mostRecentDate
        streak = 1
        
        for date in sortedWorkouts.dropFirst() {
            guard let expectedPreviousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { continue }
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
        
        let sortedWorkouts = allWorkouts
            .filter { $0.isCompleted }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
            .removingDuplicates()
        
        guard !sortedWorkouts.isEmpty else { return 0 }
        
        for date in sortedWorkouts {
            if let last = lastDate {
                let dayDifference = calendar.dateComponents([.day], from: last, to: date).day ?? 0
                if dayDifference == 1 {
                    currentStreak += 1
                } else {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = date
        }
        
        maxStreak = max(maxStreak, currentStreak)
        
        let currentStreakValue = self.currentStreak
        return max(maxStreak, currentStreakValue)
    }
    
    var totalTimeWorkedOut: TimeInterval {
        allWorkouts.reduce(0) { total, workout in
            total + workout.duration
        }
    }
    
    var completionRate: Double {
        let completed = allWorkouts.filter { $0.isCompleted }.count
        return allWorkouts.isEmpty ? 0 : Double(completed) / Double(allWorkouts.count) * 100
    }
    
    var averageRoundDuration: TimeInterval {
        var totalRoundTime: TimeInterval = 0
        var totalRounds = 0
        
        for workout in allWorkouts {
            if workout.isCompleted {
                let roundTime = Double(workout.workTime)
                let restTime = Double(workout.restTime)
                
                if workout.rounds == 1 {
                    totalRoundTime += roundTime
                    totalRounds += 1
                } else if workout.restTime == 0 {
                    totalRoundTime += roundTime * Double(workout.rounds)
                    totalRounds += Int(workout.rounds)
                } else {
                    totalRoundTime += (roundTime + restTime) * Double(workout.rounds - 1) + roundTime
                    totalRounds += Int(workout.rounds)
                }
            }
            else if workout.rounds > 1 {
                let roundTime = Double(workout.workTime)
                let restTime = Double(workout.restTime)
                let completedRounds = workout.rounds - 1
                
                if workout.restTime == 0 {
                    totalRoundTime += roundTime * Double(completedRounds)
                    totalRounds += Int(completedRounds)
                } else {
                    totalRoundTime += (roundTime + restTime) * Double(completedRounds - 1) + roundTime
                    totalRounds += Int(completedRounds)
                }
            }
        }
        
        return totalRounds == 0 ? 0 : totalRoundTime / Double(totalRounds)
    }
    
    var mostActiveDay: String {
        let calendar = Calendar.current
        var dayCount: [Int: Int] = [:]
        
        for workout in allWorkouts where workout.isCompleted {
            let weekday = calendar.component(.weekday, from: workout.date)
            dayCount[weekday, default: 0] += 1
        }
        
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
        
        var dailyDurations: [Date: TimeInterval] = [:]
        
        let dates = (-6...0).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
        
        for workout in allWorkouts {
            let workoutDay = calendar.startOfDay(for: workout.date)
            if dates.contains(workoutDay) {
                dailyDurations[workoutDay, default: 0] += workout.duration
            }
        }
        
        return dates.map { date in
            (date: date, duration: dailyDurations[date] ?? 0)
        }
    }
    
    private func deleteWorkout(_ workout: WorkoutSession) {
        if let index = dataManager.workoutHistory.firstIndex(where: { $0.id == workout.id }) {
            dataManager.deleteWorkoutSession(at: index)
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
                Picker("View", selection: $selectedTabIndex) {
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
                
                if selectedTabIndex == 0 {
                    ScrollView {
                        VStack(spacing: 20) {
                            StreakView(currentStreak: currentStreak, longestStreak: longestStreak)
                            
                            ProgressIndicatorsView(
                                totalTime: totalTimeWorkedOut,
                                completionRate: completionRate
                            )
                            
                            WeeklyGraphView(data: weeklyWorkoutData)
                            
                            WorkoutStatsView(
                                averageDuration: averageRoundDuration,
                                mostActiveDay: mostActiveDay
                            )
                            
                            WorkoutHistoryListView(
                                workouts: displayedWorkouts,
                                totalWorkouts: allWorkouts.count,
                                showAllWorkouts: $showAllWorkouts,
                                onDelete: deleteWorkout
                            )
                        }
                        .padding()
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).speed(0.8),
                            value: displayedWorkouts
                        )
                    }
                    .background(Color("Background"))
                } else {
                    StatsView(workouts: Array(allWorkouts))
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
        let yAxisMax = ceil(max(maxDuration + 1, 3))
        
        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data, id: \.date) { item in
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color("Button"))
                            .frame(width: 20, height: max(4, CGFloat(item.duration / 60) / CGFloat(yAxisMax) * 100))
                            .cornerRadius(2)
                        
                        Text(dayFormatter.string(from: item.date))
                            .font(.caption2)
                            .foregroundColor(Color("SecondaryText"))
                    }
                }
            }
            .frame(height: 120)
            
            Text("Duration (minutes)")
                .font(.caption)
                .foregroundColor(Color("SecondaryText"))
        }
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
    let workouts: [WorkoutSession]
    let totalWorkouts: Int
    @Binding var showAllWorkouts: Bool
    let onDelete: (WorkoutSession) -> Void
    @State private var showingDeleteAlert = false
    @State private var workoutToDelete: WorkoutSession?
    
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
    let workout: WorkoutSession
    let onDelete: () -> Void
    
    private var theoreticalDuration: TimeInterval {
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
    let workouts: [WorkoutSession]
    @State private var showingAllWorkouts = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
    let workouts: [WorkoutSession]
    @Binding var showingAllWorkouts: Bool
    @EnvironmentObject private var dataManager: DataManager
    @State private var workoutToDelete: WorkoutSession?
    
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
    
    private func deleteWorkout(_ workout: WorkoutSession) {
        if let index = dataManager.workoutHistory.firstIndex(where: { $0.id == workout.id }) {
            dataManager.deleteWorkoutSession(at: index)
        }
    }
}

struct WorkoutStatsCard: View {
    let workout: WorkoutSession
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sushi Session")
                    .font(.headline)
                    .foregroundColor(Color("PrimaryText"))
                
                Spacer()
                
                Text(formatDate(workout.date))
                    .font(.subheadline)
                    .foregroundColor(Color("SecondaryText"))
            }
            
            HStack(spacing: 16) {
                StatItem(title: "Roll Time", value: formatTime(Int(workout.workTime)))
                StatItem(title: "Rest Time", value: workout.restTime == 0 ? "No Rest" : formatTime(Int(workout.restTime)))
                StatItem(title: "Rolls", value: "\(workout.rounds)")
            }
            
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
        return ChronologyFormatter.renderDuration(seconds)
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




#Preview {
    HistoryView()
        .preferredColorScheme(.dark)
} 
