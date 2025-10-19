//
//  ContentView.swift
//  SparTime
//
//  Created by Mateusz Ryba on 03/08/2025.
//

import SwiftUI
import SwiftData
import AVFoundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var timeRemaining: Int = 0
    @State private var isActive = false
    @State private var currentRound = 1
    @State private var totalRounds = 2
    @State private var currentPhase: SushiPhase = .nori

    @State private var selectedProgramId: String? = nil
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?
    @State private var showingCompletion = false
    @State private var customNoriTime: Int = 5    // Nori time in seconds
    @State private var customRiceTime: Int = 5     // Rice time in seconds  
    @State private var customFishTime: Int = 5    // Fish time in seconds
    @State private var customRestTime: Int = 5     // Rest time in seconds
    @State private var customRounds: Int = 3      // Number of rolls
    @State private var isCountingDown = false
    @State private var countdownValue = 3
    @State private var workoutStartTime: Date? = nil
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingSushiHistory = false
    @StateObject private var appState = AppState()
    @Query private var userSettings: [UserSettings]
    
    init() {
        // Initialize the view
        _userSettings = Query()
    }
    
    private func loadSavedTimerSettings() {
        if let settings = userSettings.first {
            customNoriTime = settings.customWorkTime
            customRiceTime = settings.customRestTime
            customFishTime = settings.customRestTime
            customRestTime = settings.customRestTime
            customRounds = settings.customRounds
        } else {
            // Create default settings if none exist
            let settings = UserSettings(
                freeWorkoutsCount: 0,
                customWorkTime: 5,
                customRestTime: 5,
                customRounds: 3
            )
            modelContext.insert(settings)
            try? modelContext.save()
        }
    }
    
    private func saveTimerSettings() {
        if let settings = userSettings.first {
            settings.customWorkTime = customNoriTime
            settings.customRestTime = customRestTime
            settings.customRounds = customRounds
            settings.lastSyncDate = Date()
            try? modelContext.save()
        }
    }
    
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var selectedProgram: SparProgram? {
        // Always create a custom program
        return SparProgram(
            id: "custom",
            name: "Sushi Session",
            workTime: customNoriTime,
            restTime: customRestTime,
            defaultRounds: customRounds,
            description: "Custom sushi preparation configuration"
        )
    }
    
    private var currentInterval: Int {
        // Return time for current phase
        switch currentPhase {
        case .nori: return customNoriTime
        case .rice: return customRiceTime
        case .fish: return customFishTime
        case .rest: return customRestTime
        }
    }
    
    private func resetSushiSession() {
        // Reset all sushi session-related states with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            timeRemaining = 0
            currentRound = 1
            totalRounds = customRounds
            currentPhase = .nori
            progress = 0.0
            showingCompletion = false
        }
        
        // Reset other states
        isCountingDown = false
        countdownValue = 3
        workoutStartTime = nil
    }
    
    private func startSushiSession() {
        guard let program = selectedProgram else { return }
        
        // Record start time
        workoutStartTime = Date()
        
        // Start countdown
        isCountingDown = true
        countdownValue = 3
        
        // Play countdown sound and haptic
        SoundManager.shared.playSound("countdown")
        SoundManager.shared.playCountdownHaptic()
        
        // Create countdown timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
                SoundManager.shared.playCountdownHaptic()
            } else {
                timer.invalidate()
                isCountingDown = false
                
                // Play start round sound and haptic, then begin sushi session
                SoundManager.shared.playSound("bellstartround")
                SoundManager.shared.playGoHaptic()
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        guard let program = selectedProgram else { return }
        
        isActive = true
        showingCompletion = false
        
        // Set initial time for first phase (Nori)
        timeRemaining = customNoriTime
        
        progress = 1.0
        currentPhase = .nori
        
        // Set total rounds
        totalRounds = customRounds
        currentRound = 1
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                // Calculate progress based on current interval
                withAnimation(.linear(duration: 1)) {
                    progress = Double(timeRemaining) / Double(currentInterval)
                }
            } else {
                // Current phase finished, move to next phase
                if currentPhase == .rest {
                    // Rest phase finished, check if we need to start next round
                    if currentRound < totalRounds {
                        currentRound += 1
                        currentPhase = .nori
                        timeRemaining = customNoriTime
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            progress = 1.0
                        }
                        
                        // Play start round sound and haptic for next round
                        SoundManager.shared.playSound("bellstartround")
                        SoundManager.shared.playGoHaptic()
                    } else {
                        // All rounds complete
                        stopTimer(completed: true)
                        return
                    }
                } else {
                    // Move to next phase in current round
                    currentPhase = currentPhase.nextPhase
                    timeRemaining = currentInterval
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 1.0
                    }
                    
                    // Play appropriate sound for phase transition
                    if currentPhase == .rest {
                        SoundManager.shared.playSound("bellfinishround")
                        SoundManager.shared.playRestHaptic()
                    } else {
                        SoundManager.shared.playSound("bellstartround")
                        SoundManager.shared.playGoHaptic()
                    }
                }
            }
        }
    }
    
    private func stopTimer(completed: Bool = false) {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // Stop any playing sounds when stopping
        if !completed {
            SoundManager.shared.stopAllSounds()
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 0.0
            if completed {
                // Save completed sushi session to history
                saveSparToHistory(completed: true)
                // Play completion sound and success haptic
                SoundManager.shared.playSound("bellfinishround")
                SoundManager.shared.playSuccessHaptic()
                // Show completion view after saving
                showingCompletion = true
            } else {
                // Save interrupted sushi session if we have a start time
                if workoutStartTime != nil {
                    saveSparToHistory(completed: false)
                }
            }
        }
        
        // Reset states after saving
        if !completed {
            isActive = false
            resetSushiSession()
        } else {
            // For completed sushi sessions, keep the completion view visible
            isActive = false
            // Don't reset immediately to show completion view
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                resetSushiSession()
            }
        }
    }
    
        private func saveSparToHistory(completed: Bool) {
        guard let program = selectedProgram,
              let startTime = workoutStartTime else { return }
        
        var duration: TimeInterval
        var rounds: Int
        
        if completed {
            // For completed sushi sessions, use theoretical time
            let totalPhaseTime = Double(customNoriTime + customRiceTime + customFishTime)
            let restTime = Double(customRestTime)
            // Calculate total time: (work time + rest time) * (rounds - 1) + work time for last round
            if customRounds == 1 {
                duration = totalPhaseTime
            } else if customRestTime == 0 {
                // No rest between rounds
                duration = totalPhaseTime * Double(customRounds)
            } else {
                // With rest between rounds - don't count rest after last round
                duration = (totalPhaseTime + restTime) * Double(customRounds - 1) + totalPhaseTime
            }
            
            // Debug print to check calculation
            print("🔍 [Duration] Phase time: \(totalPhaseTime)s, Rest time: \(customRestTime)s, Rounds: \(customRounds)")
            print("🔍 [Duration] Calculated duration: \(duration)s (\(Int(duration/60)):\(String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 60))))")
            
            rounds = customRounds
        } else {
            // For interrupted sushi sessions
            if isCountingDown {
                // If stopped during countdown, don't save to history
                return
            }
            
            // For other interrupted sushi sessions, use actual time spent
            duration = Date().timeIntervalSince(startTime)
            
            // Remove the countdown duration (3 seconds)
            duration = max(1, duration - 3)
            
            // Handle special cases for interrupted sushi sessions
            if !isActive {
                // If stopped before becoming active, don't save to history
                return
            }
            
            rounds = max(1, currentRound)
        }
        
        let workout = WorkoutHistory(
            name: program.name,
            date: startTime,
            duration: duration,
            rounds: rounds,
            isCompleted: completed,
            workoutType: program.id,
            workTime: customNoriTime,
            restTime: customRestTime
        )
        
        // Save to CloudKit
        modelContext.insert(workout)
        do {
            try modelContext.save()
            print("✅ [CloudKit] Sushi session saved successfully")
        } catch {
            print("❌ [CloudKit] Error saving sushi session: \(error)")
        }
        
        // All features are now free
        print("✅ Sushi session completed successfully")
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 50)
                        
                        ZStack {
                        // Background circle
                        Circle()
                            .stroke(lineWidth: 35)
                            .opacity(0.3)
                            .foregroundColor(Color("TimerRingBackground"))
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(style: StrokeStyle(
                                lineWidth: 35,
                                lineCap: .round
                            ))
                            .foregroundStyle(
                                currentPhase == .rest ?
                                LinearGradient(colors: [Color("TimerRingRest"), Color("TimerRingRest").opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color("TimerRingRound"), Color("TimerRingRound").opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(
                                color: (currentPhase == .rest ? Color("TimerRingRest") : Color("TimerRingRound")).opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                            .animation(.linear(duration: 0.25), value: progress)
                        
                        // Timer display
                        if showingCompletion {
                            CompletionView()
                        } else if isCountingDown {
                            // Countdown display
                            Text("\(countdownValue)")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(Color("PrimaryText"))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            VStack(spacing: 8) {
                                Text("\(timeRemaining / 60):\(String(format: "%02d", timeRemaining % 60))")
                                    .font(.system(size: 50, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(isActive ? Color("PrimaryText") : Color("TimerInactiveText"))
                                    .transition(.opacity)
                                
                                if isActive {
                                    Text(currentPhase.displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color("SecondaryText"))
                                        .transition(.opacity)
                                }
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: timeRemaining)
                            .animation(.easeInOut(duration: 0.5), value: isActive)
                            .animation(.easeInOut(duration: 0.5), value: currentPhase)
                        }
                    }
                    .frame(width: 300, height: 320)
                    .padding(.vertical, 20)
                    
                    // Bottom panel with dark background
                    VStack(spacing: 0) {
                        // Start/Stop button
                        HStack {
                            Spacer()
                            Button(action: {
                                if isActive || isCountingDown {
                                    stopTimer()
                                } else if let program = selectedProgram {
                                    startSushiSession()
                                }
                            }) {
                                Text(isActive || isCountingDown ? "STOP" : "START")
                                    .font(.headline)
                                    .foregroundColor(Color("ButtonText"))
                                    .frame(width: 120, height: 44)
                                    .background(
                                        isActive || isCountingDown ?
                                        LinearGradient(
                                            colors: [
                                                Color.red.opacity(1.2),
                                                Color.red,
                                                Color.red.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        selectedProgram != nil ?
                                        LinearGradient(
                                            colors: [
                                                Color("Button").opacity(1.2),
                                                Color("Button"),
                                                Color("Button").opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            colors: [
                                                Color(.systemGray).opacity(1.2),
                                                Color(.systemGray),
                                                Color(.systemGray).opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(15)
                                    .shadow(
                                        color: (isActive || isCountingDown) ? 
                                            Color.red.opacity(0.3) : 
                                            (selectedProgram != nil ? Color("Button").opacity(0.3) : Color(.systemGray).opacity(0.3)),
                                        radius: 5,
                                        x: 0,
                                        y: 2
                                    )
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Custom Sushi View always visible
                        CustomSparView(
                            noriTime: $customNoriTime,
                            riceTime: $customRiceTime,
                            fishTime: $customFishTime,
                            restTime: $customRestTime,
                            rounds: $customRounds,
                            selectedProgramId: $selectedProgramId,
                            onSettingsChanged: saveTimerSettings
                        )
                        Spacer()
                    }
                    .background(Color("Background"))
                    .cornerRadius(50, corners: [.topLeft, .topRight])
                    .ignoresSafeArea(edges: .bottom)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("Background"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image("item_settings")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingSushiHistory = true
                        }) {
                            Image("item_reset")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image("item_analytics")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadSavedTimerSettings()
            appState.incrementSessionCount()
            appState.checkIfShouldPromptForRating()
        }
        .fullScreenCover(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingSushiHistory) {
            SushiHistoryView()
        }
    }
}

// MARK: - Supporting Views

struct CompletionView: View {
    var body: some View {
        ZStack {
            // Background circle (transparent)
            Circle()
                .stroke(lineWidth: 35)
                .opacity(0.3)
                .foregroundColor(Color("Accent"))
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            
            // Gradient circle
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 35))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color("Accent"),
                            Color("Accent").opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color("Accent").opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 5
                )
            
            VStack(spacing: 12) {
                // Trophy with gradient
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .yellow,
                                .orange
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: .orange.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Text("Great Job!")
                    .font(.title2.bold())
                    .foregroundColor(Color("PrimaryText"))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

struct CustomSparView: View {
    @Binding var noriTime: Int
    @Binding var riceTime: Int
    @Binding var fishTime: Int
    @Binding var restTime: Int
    @Binding var rounds: Int
    @Binding var selectedProgramId: String?
    let onSettingsChanged: () -> Void
    
    @State private var showingWorkTimePicker = false
    @State private var showingRestTimePicker = false
    @State private var showingRoundsPicker = false
    @State private var showingFishTimePicker = false
    @State private var showingRiceTimePicker = false
    
    // Time selection states
    @State private var workMinutes: Int = 0
    @State private var workSeconds: Int = 20
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 10
    @State private var fishMinutes: Int = 0
    @State private var fishSeconds: Int = 20
    @State private var riceMinutes: Int = 0
    @State private var riceSeconds: Int = 10
    
    // Time options
    let minuteOptions = Array(0...7)  // 0-7 minutes (increased for rolling time)
    let restMinuteOptions = Array(0...2)  // 0-2 minutes for rest time (more realistic)
    let secondOptions = Array(0...59) // 0-59 seconds
    let roundsOptions = Array(1...20) // 1-20 rolls (decreased for realism)
    
    var body: some View {
        VStack(spacing: 16) {
            // Nori Time
            Button(action: {
                // Initialize the picker values
                workMinutes = noriTime / 60
                workSeconds = noriTime % 60
                showingWorkTimePicker = true
            }) {
                HStack {
                    Image("item_nori")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Nori Time")
                        .foregroundColor(Color("PrimaryText"))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatTime(noriTime))
                        .foregroundColor(Color("SecondaryText"))
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Button"), lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingWorkTimePicker) {
                NavigationView {
                    VStack {
                        HStack {
                            // Minutes picker
                            Picker("Minutes", selection: $workMinutes) {
                                ForEach(minuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
                            // Seconds picker
                            Picker("Seconds", selection: $workSeconds) {
                                ForEach(secondOptions, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("sec")
                                .foregroundColor(Color("SecondaryText"))
                        }
                        .padding()
                    }
                    .navigationTitle("Nori Time")
                    .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                noriTime = (workMinutes * 60) + workSeconds
                                onSettingsChanged()
                                showingWorkTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(250)])
            }
            
            // Rice Time
            Button(action: {
                // Initialize the picker values
                riceMinutes = riceTime / 60
                riceSeconds = riceTime % 60
                showingRiceTimePicker = true
            }) {
                HStack {
                    Image("item_rice")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Rice Time")
                        .foregroundColor(Color("PrimaryText"))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatTime(riceTime))
                        .foregroundColor(Color("SecondaryText"))
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Button"), lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingRiceTimePicker) {
                NavigationView {
                    VStack {
                        HStack {
                            // Minutes picker
                            Picker("Minutes", selection: $riceMinutes) {
                                ForEach(restMinuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
                            // Seconds picker
                            Picker("Seconds", selection: $riceSeconds) {
                                ForEach(secondOptions, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("sec")
                                .foregroundColor(Color("SecondaryText"))
                        }
                        .padding()
                    }
                    .navigationTitle("Rice Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                riceTime = (riceMinutes * 60) + riceSeconds
                                onSettingsChanged()
                                showingRiceTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(250)])
            }
            
            // Fish Time
            Button(action: {
                // Initialize the picker values for fish time
                fishMinutes = fishTime / 60
                fishSeconds = fishTime % 60
                showingFishTimePicker = true
            }) {
                HStack {
                    Image("item_filling")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Fish Time")
                        .foregroundColor(Color("PrimaryText"))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatTime(fishTime))
                        .foregroundColor(Color("SecondaryText"))
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Button"), lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingFishTimePicker) {
                NavigationView {
                    VStack {
                        HStack {
                            // Minutes picker
                            Picker("Minutes", selection: $fishMinutes) {
                                ForEach(minuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
                            // Seconds picker
                            Picker("Seconds", selection: $fishSeconds) {
                                ForEach(secondOptions, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("sec")
                                .foregroundColor(Color("SecondaryText"))
                        }
                        .padding()
                    }
                    .navigationTitle("Fish Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                fishTime = (fishMinutes * 60) + fishSeconds
                                onSettingsChanged()
                                showingFishTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(250)])
            }
            
            // Rest Time
            Button(action: {
                // Initialize the picker values
                restMinutes = restTime / 60
                restSeconds = restTime % 60
                showingRestTimePicker = true
            }) {
                HStack {
                    Image("item_reset")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Rest Time")
                        .foregroundColor(Color("PrimaryText"))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text(restTime == 0 ? "No Rest" : formatTime(restTime))
                        .foregroundColor(Color("SecondaryText"))
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Button"), lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingRestTimePicker) {
                NavigationView {
                    VStack {
                        HStack {
                            // Minutes picker
                            Picker("Minutes", selection: $restMinutes) {
                                ForEach(restMinuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
                            // Seconds picker
                            Picker("Seconds", selection: $restSeconds) {
                                ForEach(secondOptions, id: \.self) { second in
                                    Text(String(format: "%02d", second)).tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("sec")
                                .foregroundColor(Color("SecondaryText"))
                        }
                        .padding()
                    }
                    .navigationTitle("Rest Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                restTime = (restMinutes * 60) + restSeconds
                                onSettingsChanged()
                                showingRestTimePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(250)])
            }
            
            
            // Rolls
            Button(action: {
                showingRoundsPicker = true
            }) {
                HStack {
                    Image("item_filling")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("Rolls")
                        .foregroundColor(Color("PrimaryText"))
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(rounds)")
                        .foregroundColor(Color("SecondaryText"))
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SecondaryText"))
                }
                .padding()
                .background(Color("Button"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("Button"), lineWidth: 2)
                )
            }
            .sheet(isPresented: $showingRoundsPicker) {
                NavigationView {
                    VStack {
                        Picker("Rolls", selection: $rounds) {
                            ForEach(roundsOptions, id: \.self) { number in
                                Text("\(number) rolls").tag(number)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .navigationTitle("Number of Rolls")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                onSettingsChanged()
                                showingRoundsPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(250)])
            }
        }
        .padding()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            if remainingSeconds == 0 {
                return "\(minutes) min"
            } else {
                return "\(minutes) min \(remainingSeconds) sec"
            }
        } else {
            return "\(seconds) sec"
        }
    }
}

// MARK: - Data Models

struct SparProgram {
    let id: String
    let name: String
    let workTime: Int
    let restTime: Int
    let defaultRounds: Int
    let description: String
}



// Helper extension to apply corner radius to specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Sushi Phases

enum SushiPhase: String, CaseIterable {
    case nori = "Nori"
    case rice = "Rice" 
    case fish = "Fish"
    case rest = "Rest"
    
    var displayName: String {
        return self.rawValue
    }
    
    var nextPhase: SushiPhase {
        switch self {
        case .nori: return .rice
        case .rice: return .fish
        case .fish: return .rest
        case .rest: return .nori
        }
    }
}
