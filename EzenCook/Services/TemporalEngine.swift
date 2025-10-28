import Foundation
import Combine

protocol TemporalEngineContract {
    var isActive: Bool { get }
    var timeRemaining: Int { get }
    var currentPhase: PreparationLayer { get }
    var currentRound: Int { get }
    var totalRounds: Int { get }
    var progress: Double { get }
    
    func initiateCycle(workTime: Int, restTime: Int, rounds: Int)
    func terminateCycle()
    func suspendCycle()
    func reviveCycle()
    func resetTimer()
}

class TemporalEngine: ObservableObject, TemporalEngineContract {
    @Published var isActive: Bool = false
    @Published var timeRemaining: Int = 0
    @Published var currentPhase: PreparationLayer = .foundation
    @Published var currentRound: Int = 1
    @Published var totalRounds: Int = 2
    @Published var progress: Double = 0.0
    
    private var timer: Timer?
    private var workTime: Int = 0
    private var restTime: Int = 0
    private var isPaused: Bool = false
    
    func initiateCycle(workTime: Int, restTime: Int, rounds: Int) {
        self.workTime = workTime
        self.restTime = restTime
        self.totalRounds = rounds
        self.currentRound = 1
        self.currentPhase = .foundation
        self.isActive = true
        self.isPaused = false
        
        startCurrentPhase()
    }
    
    func terminateCycle() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        resetToInitialState()
    }
    
    func suspendCycle() {
        guard isActive && !isPaused else { return }
        timer?.invalidate()
        timer = nil
        isPaused = true
    }
    
    func reviveCycle() {
        guard isActive && isPaused else { return }
        isPaused = false
        startCurrentPhase()
    }
    
    func resetTimer() {
        terminateCycle()
        resetToInitialState()
    }
    
    private func startCurrentPhase() {
        let phaseTime = getPhaseTime()
        timeRemaining = phaseTime
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        guard isActive && !isPaused else { return }
        
        timeRemaining -= 1
        updateProgress()
        
        if timeRemaining <= 0 {
            completeCurrentPhase()
        }
    }
    
    private func completeCurrentPhase() {
        timer?.invalidate()
        timer = nil
        
        switch currentPhase {
        case .foundation:
            currentPhase = .base
            startCurrentPhase()
        case .base:
            currentPhase = .complement
            startCurrentPhase()
        case .complement:
            if currentRound < totalRounds {
                currentPhase = .interval
                startCurrentPhase()
            } else {
                completeSession()
            }
        case .interval:
            currentRound += 1
            if currentRound <= totalRounds {
                currentPhase = .foundation
                startCurrentPhase()
            } else {
                completeSession()
            }
        }
    }
    
    private func completeSession() {
        isActive = false
        currentPhase = .foundation
    }
    
    private func getPhaseTime() -> Int {
        switch currentPhase {
        case .foundation, .base, .complement:
            return workTime
        case .interval:
            return restTime
        }
    }
    
    private func updateProgress() {
        let phaseTime = getPhaseTime()
        progress = Double(phaseTime - timeRemaining) / Double(phaseTime)
    }
    
    private func resetToInitialState() {
        timeRemaining = 0
        currentPhase = .foundation
        currentRound = 1
        totalRounds = 2
        progress = 0.0
    }
}

enum PreparationLayer: String, CaseIterable {
    case foundation = "Nori"
    case base = "Rice" 
    case complement = "Fish"
    case interval = "Rest"
    
    var displayName: String {
        return self.rawValue
    }
    
    var nextPhase: PreparationLayer {
        switch self {
        case .foundation: return .base
        case .base: return .complement
        case .complement: return .interval
        case .interval: return .foundation
        }
    }
}
