//
//  AppState.swift
//  BeastInterval
//
//  Created by Mateusz Ryba on 05/04/2025.
//

import Foundation
import SwiftUI
import StoreKit

class AppState: ObservableObject {
    @Published var sessionCount: Int = UserDefaults.standard.integer(forKey: "sessionCount")
    @Published var hasRated: Bool = UserDefaults.standard.bool(forKey: "hasRated")

    // Increment session count
    func incrementSessionCount() {
        sessionCount += 1
        UserDefaults.standard.set(sessionCount, forKey: "sessionCount")
    }

    // Check if the user should be prompted for rating
    func checkIfShouldPromptForRating() {
        if hasRated {
            return // User has already rated the app
        }

        if sessionCount >= 5 {
            sessionCount = 0
            UserDefaults.standard.set(0, forKey: "sessionCount")
            promptForRating()
        }
    }

    // Prompt the user to rate the app
    func promptForRating() {
        if #available(iOS 14.0, *) {
            // Delay for better UX (e.g. after a workout finishes)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                SKStoreReviewController.requestReview()
            }
        } else {
            // Fallback: open App Store page
            if let url = URL(string: "itms-apps://apps.apple.com/app/id6749504612") {
                UIApplication.shared.open(url)
            }
        }

        // Mark as rated to avoid prompting again
        UserDefaults.standard.set(true, forKey: "hasRated")
        hasRated = true
    }
}
