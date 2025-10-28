import SwiftUI
import AVFoundation

struct MainCanvas: View {
    
    
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var applicationOrchestrator = ApplicationOrchestrator()
    
    
    @State private var remainingDuration: Int = 0
    @State private var isCycleEngaged = false
    @State private var activeIteration = 1
    @State private var plannedIterations = 2
    @State private var activeLayer: PreparationLayer = .foundation
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var countdownTimer: Timer?
    @State private var sessionInitiationMoment: Date? = nil
    
    
    @State private var isPrelaunching = false
    @State private var countdownValue = 3
    
    
    @State private var foundationDuration: Int = 5
    @State private var baseDuration: Int = 5
    @State private var complementDuration: Int = 5
    @State private var intervalDuration: Int = 5
    @State private var iterationQuantity: Int = 3
    
    
    @State private var selectedProgramId: String? = nil
    @State private var showingCompletion = false
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var showingSushiHistory = false
    
    
    init() {
    }
    
    
    private func loadSavedTimerSettings() {
        foundationDuration = dataManager.userSettings.customWorkTime
        baseDuration = dataManager.userSettings.customRestTime
        complementDuration = dataManager.userSettings.customRestTime
        intervalDuration = dataManager.userSettings.customRestTime
        iterationQuantity = dataManager.userSettings.customRounds
    }
    
    private func saveTimerSettings() {
        dataManager.userSettings.customWorkTime = foundationDuration
        dataManager.userSettings.customRestTime = intervalDuration
        dataManager.userSettings.customRounds = iterationQuantity
        dataManager.userSettings.lastSyncDate = Date()
        dataManager.saveUserSettings()
    }
    
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var selectedProgram: SparProgram? {
        return SparProgram(
            id: "custom",
            name: "Sushi Session",
            workTime: foundationDuration,
            restTime: intervalDuration,
            defaultRounds: iterationQuantity,
            description: "Custom sushi preparation configuration"
        )
    }
    
    private var currentInterval: Int {
        switch activeLayer {
        case .foundation: return foundationDuration
        case .base: return baseDuration
        case .complement: return complementDuration
        case .interval: return intervalDuration
        }
    }
    
    
    private func reinitializeWorkflow() {
        withAnimation(.easeInOut(duration: 0.5)) {
            remainingDuration = 0
            activeIteration = 1
            plannedIterations = iterationQuantity
            activeLayer = .foundation
            progress = 0.0
            showingCompletion = false
        }
        
        isPrelaunching = false
        countdownValue = 3
        sessionInitiationMoment = nil
    }
    
    private func initiatePreparationCycle() {
        guard selectedProgram != nil else { return }
        
        sessionInitiationMoment = Date()
        
        isPrelaunching = true
        countdownValue = 3
        
        AcousticOrchestrator.shared.triggerAudioClip("countdown")
        AcousticOrchestrator.shared.playCountdownHaptic()
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
                AcousticOrchestrator.shared.playCountdownHaptic()
            } else {
                timer.invalidate()
                isPrelaunching = false
                
                AcousticOrchestrator.shared.triggerAudioClip("bellstartround")
                AcousticOrchestrator.shared.executeImpactResponse()
                startTimer()
            }
        }
    }
    
    
    private func startTimer() {
        guard selectedProgram != nil else { return }
        
        isCycleEngaged = true
        showingCompletion = false
        
        remainingDuration = foundationDuration
        
        progress = 1.0
        activeLayer = .foundation
        
        plannedIterations = iterationQuantity
        activeIteration = 1
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingDuration > 0 {
                remainingDuration -= 1
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 1)) {
                        progress = Double(remainingDuration) / Double(currentInterval)
                    }
                }
            } else {
                if activeLayer == .interval {
                    if activeIteration < plannedIterations {
                        activeIteration += 1
                        activeLayer = .foundation
                        remainingDuration = foundationDuration
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            progress = 1.0
                        }
                        
                        AcousticOrchestrator.shared.triggerAudioClip("bellstartround")
                        AcousticOrchestrator.shared.executeImpactResponse()
                    } else {
                        haltTemporalSequence(completed: true)
                        return
                    }
                } else {
                    activeLayer = activeLayer.nextPhase
                    remainingDuration = currentInterval
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        progress = 1.0
                    }
                    
                    if activeLayer == .interval {
                        AcousticOrchestrator.shared.triggerAudioClip("bellfinishround")
                        AcousticOrchestrator.shared.playRestHaptic()
                    } else {
                        AcousticOrchestrator.shared.triggerAudioClip("bellstartround")
                        AcousticOrchestrator.shared.executeImpactResponse()
                    }
                }
            }
        }
    }
    
    private func haltTemporalSequence(completed: Bool = false) {
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        if !completed {
            AcousticOrchestrator.shared.stopAllSounds()
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 0.0
            if completed {
                persistSessionRecord(completed: true)
                AcousticOrchestrator.shared.triggerAudioClip("bellfinishround")
                AcousticOrchestrator.shared.playSuccessHaptic()
                showingCompletion = true
            } else {
                if sessionInitiationMoment != nil {
                    persistSessionRecord(completed: false)
                }
            }
        }
        
        if !completed {
            isCycleEngaged = false
            reinitializeWorkflow()
        } else {
            isCycleEngaged = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                reinitializeWorkflow()
            }
        }
    }
    
        private func persistSessionRecord(completed: Bool) {
        guard let program = selectedProgram,
              let startTime = sessionInitiationMoment else { return }
        
        var duration: TimeInterval
        var rounds: Int
        
        if completed {
            let totalPhaseTime = Double(foundationDuration + baseDuration + complementDuration)
            let restTime = Double(intervalDuration)
            if iterationQuantity == 1 {
                duration = totalPhaseTime
            } else if intervalDuration == 0 {
                duration = totalPhaseTime * Double(iterationQuantity)
            } else {
                duration = (totalPhaseTime + restTime) * Double(iterationQuantity - 1) + totalPhaseTime
            }
            
            print("🔍 [Duration] Phase time: \(totalPhaseTime)s, Rest time: \(intervalDuration)s, Rounds: \(iterationQuantity)")
            print("🔍 [Duration] Calculated duration: \(duration)s (\(Int(duration/60)):\(String(format: "%02d", Int(duration.truncatingRemainder(dividingBy: 60))))")
            
            rounds = iterationQuantity
        } else {
            if isPrelaunching {
                return
            }
            
            duration = Date().timeIntervalSince(startTime)
            
            duration = max(1, duration - 3)
            
            if !isCycleEngaged {
                return
            }
            
            rounds = max(1, activeIteration)
        }
        
        let workout = WorkoutSession(
            name: program.name,
            date: startTime,
            duration: duration,
            rounds: rounds,
            isCompleted: completed,
            workoutType: program.id,
            workTime: foundationDuration,
            restTime: intervalDuration
        )
        
        dataManager.addWorkoutSession(workout)
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
                        
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(style: StrokeStyle(
                                lineWidth: 35,
                                lineCap: .round
                            ))
                            .foregroundStyle(
                                activeLayer == .interval ?
                                LinearGradient(colors: [Color("TimerRingRest"), Color("TimerRingRest").opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [Color("TimerRingRound"), Color("TimerRingRound").opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(
                                color: (activeLayer == .interval ? Color("TimerRingRest") : Color("TimerRingRound")).opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                            .animation(.linear(duration: 0.25), value: progress)
                        
                        if showingCompletion {
                            VictoryDisplay()
                        } else if isPrelaunching {
                            Text("\(countdownValue)")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundColor(Color("PrimaryText"))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            VStack(spacing: 8) {
                                Text("\(remainingDuration / 60):\(String(format: "%02d", remainingDuration % 60))")
                                    .font(.system(size: 50, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundColor(isCycleEngaged ? Color("PrimaryText") : Color("TimerInactiveText"))
                                    .transition(.opacity)
                                
                                if isCycleEngaged {
                                    Text(activeLayer.displayName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color("SecondaryText"))
                                        .transition(.opacity)
                                }
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.5), value: remainingDuration)
                            .animation(.easeInOut(duration: 0.5), value: isCycleEngaged)
                            .animation(.easeInOut(duration: 0.5), value: activeLayer)
                        }
                    }
                    .frame(width: 300, height: 320)
                    .padding(.vertical, 20)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button(action: {
                                if isCycleEngaged || isPrelaunching {
                                    haltTemporalSequence()
                                } else if selectedProgram != nil {
                                    initiatePreparationCycle()
                                }
                            }) {
                                Text(isCycleEngaged || isPrelaunching ? "STOP" : "START")
                                    .font(.headline)
                                    .foregroundColor(Color("ButtonText"))
                                    .frame(width: 120, height: 44)
                                    .background(
                                        isCycleEngaged || isPrelaunching ?
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
                                        color: (isCycleEngaged || isPrelaunching) ? 
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
                        
                        SessionConfigurator(
                            noriTime: $foundationDuration,
                            riceTime: $baseDuration,
                            fishTime: $complementDuration,
                            restTime: $intervalDuration,
                            rounds: $iterationQuantity,
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
                .onAppear {
                    if #available(iOS 16.0, *) {
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if #available(iOS 16.0, *) {
                }
            }
        .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image("config_controls")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingSushiHistory = true
                        }) {
                            Image("interval_state")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                        }
                        
                        Button(action: {
                            showingHistory = true
                        }) {
                            Image("metrics_dashboard")
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
            applicationOrchestrator.advanceSessionRegistry()
            applicationOrchestrator.evaluateReviewEligibility()
        }
        .fullScreenCover(isPresented: $showingHistory) {
            HistoryView()
        }
        .sheet(isPresented: $showingSettings) {
            ConfigurationPanel()
        }
        .sheet(isPresented: $showingSushiHistory) {
            CulinaryChronicles()
        }
    }
}


struct VictoryDisplay: View {
    var body: some View {
        ZStack {
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

struct SessionConfigurator: View {
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
    
    @State private var workMinutes: Int = 0
    @State private var workSeconds: Int = 20
    @State private var restMinutes: Int = 0
    @State private var restSeconds: Int = 10
    @State private var fishMinutes: Int = 0
    @State private var fishSeconds: Int = 20
    @State private var riceMinutes: Int = 0
    @State private var riceSeconds: Int = 10
    
    let minuteOptions = Array(0...7)  // 0-7 minutes (increased for rolling time)
    let restMinuteOptions = Array(0...2)  // 0-2 minutes for rest time (more realistic)
    let secondOptions = Array(0...59) // 0-59 seconds
    let roundsOptions = Array(1...20) // 1-20 rolls (decreased for realism)
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                workMinutes = noriTime / 60
                workSeconds = noriTime % 60
                showingWorkTimePicker = true
            }) {
                HStack {
                    Image("foundation_layer")
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
                            Picker("Minutes", selection: $workMinutes) {
                                ForEach(minuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
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
            }
            
            Button(action: {
                riceMinutes = riceTime / 60
                riceSeconds = riceTime % 60
                showingRiceTimePicker = true
            }) {
                HStack {
                    Image("base_component")
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
                            Picker("Minutes", selection: $riceMinutes) {
                                ForEach(restMinuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
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
            }
            
            Button(action: {
                fishMinutes = fishTime / 60
                fishSeconds = fishTime % 60
                showingFishTimePicker = true
            }) {
                HStack {
                    Image("complement_element")
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
                            Picker("Minutes", selection: $fishMinutes) {
                                ForEach(minuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
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
            }
            
            Button(action: {
                restMinutes = restTime / 60
                restSeconds = restTime % 60
                showingRestTimePicker = true
            }) {
                HStack {
                    Image("interval_state")
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
                            Picker("Minutes", selection: $restMinutes) {
                                ForEach(restMinuteOptions, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            
                            Text("min")
                                .foregroundColor(Color("SecondaryText"))
                            
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
            }
            
            
            Button(action: {
                showingRoundsPicker = true
            }) {
                HStack {
                    Image("complement_element")
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
            }
        }
        .padding()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        return ChronologyFormatter.renderDuration(seconds)
    }
}


struct SparProgram {
    let id: String
    let name: String
    let workTime: Int
    let restTime: Int
    let defaultRounds: Int
    let description: String
}



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

