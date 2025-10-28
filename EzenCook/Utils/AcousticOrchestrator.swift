import AVFoundation
import UIKit
import SwiftUI

class AcousticOrchestrator {
    
    
    static let shared = AcousticOrchestrator()
    
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let heavyImpactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    @AppStorage("voiceFeedbackEnabled") private var isVoiceFeedbackEnabled = true
    
    
    private init() {
        configureAudioSession()
        loadEzenCookSounds()
        prepareHapticFeedback()
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
    
    private func loadEzenCookSounds() {
        loadSound("bellfinishround", type: "mp3")
        loadSound("bellstartround", type: "mp3")
        loadSound("countdown", type: "mp3")
    }
    
    private func prepareHapticFeedback() {
        impactFeedback.prepare()
        lightImpactFeedback.prepare()
        heavyImpactFeedback.prepare()
        notificationFeedback.prepare()
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
    
    func triggerAudioClip(_ soundName: String) {
        guard isVoiceFeedbackEnabled else { return }
        if let player = audioPlayers[soundName] {
            player.currentTime = 0
            player.play()
        }
    }
    
    func stopSound(_ soundName: String) {
        if let player = audioPlayers[soundName] {
            player.stop()
        }
    }
    
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    
    func executeImpactResponse() {
        impactFeedback.impactOccurred()
    }
    
    func playRestHaptic() {
        lightImpactFeedback.impactOccurred()
    }
    
    func playCountdownHaptic() {
        heavyImpactFeedback.impactOccurred()
    }
    
    func playSuccessHaptic() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    func playErrorHaptic() {
        notificationFeedback.notificationOccurred(.error)
    }
}
