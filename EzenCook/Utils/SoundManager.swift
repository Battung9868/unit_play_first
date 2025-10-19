import AVFoundation
import UIKit
import SwiftUI

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    @AppStorage("voiceFeedbackEnabled") private var voiceFeedbackEnabled = true
    
    private init() {
        // Configure audio session for background playback
        configureAudioSession()
        
        // Load SparTime specific sounds
        loadSound("bellfinishround", type: "mp3")
        loadSound("bellstartround", type: "mp3")
        loadSound("countdown", type: "mp3")
        
        // Prepare haptic feedback
        impactFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ [Audio] Background audio session configured")
        } catch {
            print("❌ [Audio] Failed to configure audio session: \(error)")
        }
    }
    
    private func loadSound(_ name: String, type: String) {
        if let path = Bundle.main.path(forResource: name, ofType: type) {
            do {
                let url = URL(fileURLWithPath: path)
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                audioPlayers[name] = player
            } catch {
                print("Error loading sound \(name): \(error.localizedDescription)")
            }
        }
    }
    
    func playSound(_ name: String) {
        guard voiceFeedbackEnabled else { return }
        if let player = audioPlayers[name] {
            player.currentTime = 0
            player.play()
        }
    }
    
    func stopSound(_ name: String) {
        if let player = audioPlayers[name] {
            player.stop()
        }
    }
    
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    // Haptic feedback functions
    func playCountdownHaptic() {
        impactFeedback.impactOccurred(intensity: 0.7)
    }
    
    func playGoHaptic() {
        impactFeedback.impactOccurred(intensity: 1.0)
    }
    
    func playRestHaptic() {
        impactFeedback.impactOccurred(intensity: 0.5)
    }
    
    func playSuccessHaptic() {
        notificationFeedback.notificationOccurred(.success)
    }
} 