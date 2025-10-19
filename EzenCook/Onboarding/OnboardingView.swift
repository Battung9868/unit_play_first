import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pages: [OnboardingPageModel]
    private let onFinish: () -> Void
    
    init(pages: [OnboardingPageModel], onFinish: @escaping () -> Void) {
        self.pages = pages
        self.onFinish = onFinish
    }
    
    var body: some View {
        ZStack {
            if currentPage < pages.count {
                OnboardingPage(model: pages[currentPage]) {
                    nextPage()
                }
            }
        }
        .animation(.easeInOut, value: currentPage)
    }
    
    private func nextPage() {
        if currentPage == pages.count - 1 {
            onFinish()
        } else {
            currentPage += 1
        }
    }
}

// Example usage for FastZen
struct FastZenOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(
            pages: [
                OnboardingPageModel(
                    title: "Welcome to FastZen",
                    description: "Track your fasts, stay motivated, and unlock premium features!\n\nWe'll ask for notification permission to remind you about your fasting schedule.",
                    imageName: "purchaseview-hero"
                ),
                OnboardingPageModel(
                    title: "How to Start Fasting",
                    description: "1. Go to Settings\n2. Choose your fasting plan\n3. Go back to Fasting tab and press Start",
                    imageName: nil,
                    showsContinue: true,
                    showsPrimaryAction: false,
                    onAppearAction: {
                    }
                ),
                OnboardingPageModel(
                    title: "Free vs Premium",
                    description: "Free: Track up to 4 fasts, basic protocols\nPremium: Unlimited fasts, advanced protocols, detailed stats",
                    imageName: nil,
                    showsContinue: false,
                    showsPrimaryAction: true,
                    primaryActionTitle: "Start Free Trial",
                    primaryAction: {},
                    showsSecondaryAction: true,
                    secondaryActionTitle: "Skip for now",
                    secondaryAction: nil
                )
            ],
            onFinish: {}
        )
    }
} 
