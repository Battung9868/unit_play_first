import Foundation
import SwiftUI
import StoreKit
import Combine

class ApplicationOrchestrator: ObservableObject {
    @Published var sessionCount: Int = UserDefaults.standard.integer(forKey: "sessionCount")
    @Published var hasRated: Bool = UserDefaults.standard.bool(forKey: "hasRated")
    
    private let ratingPromptThreshold = 5
    private let ratingPromptDelay: TimeInterval = 2.0

    func advanceSessionRegistry() {
        sessionCount += 1
        UserDefaults.standard.set(sessionCount, forKey: "sessionCount")
    }
    
    func evaluateReviewEligibility() {
        guard !hasRated else { return }
        
        if sessionCount >= ratingPromptThreshold {
            resetSessionCount()
            promptForRating()
        }
    }
    
    private func resetSessionCount() {
        sessionCount = 0
        UserDefaults.standard.set(0, forKey: "sessionCount")
    }
    
    func promptForRating() {
        DispatchQueue.main.asyncAfter(deadline: .now() + ratingPromptDelay) {
            if #available(iOS 14.0, *) {
                SKStoreReviewController.requestReview()
            } else {
                self.openAppStorePage()
            }
        }
        
        markAsRated()
    }
    
    private func openAppStorePage() {
        if let url = URL(string: "itms-apps://apps.apple.com/app/id6749504612") {
            UIApplication.shared.open(url)
        }
    }
    
    private func markAsRated() {
        UserDefaults.standard.set(true, forKey: "hasRated")
        hasRated = true
    }
}
