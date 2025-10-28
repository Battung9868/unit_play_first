import SwiftUI
import UserNotifications

struct IntroductionCarousel: View {
    
    
    @State private var currentPageIndex = 0
    
    private let onboardingPages: [SlideConfiguration]
    
    private let onFinish: () -> Void
    
    
    init(pages: [SlideConfiguration], onFinish: @escaping () -> Void) {
        self.onboardingPages = pages
        self.onFinish = onFinish
    }
    
    
    var body: some View {
        ZStack {
            if currentPageIndex < onboardingPages.count {
                IntroductionSlide(pageModel: onboardingPages[currentPageIndex]) {
                    advanceToNextSlide()
                }
            }
        }
        .animation(.easeInOut, value: currentPageIndex)
    }
    
    
    private func advanceToNextSlide() {
        if currentPageIndex == onboardingPages.count - 1 {
            onFinish()
        } else {
            currentPageIndex += 1
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionCarousel(
            pages: [
                SlideConfiguration(
                    title: "Welcome to EzenCook",
                    description: "Track your sushi sessions, stay motivated, and unlock premium features!\n\nWe'll help you perfect your sushi rolling technique.",
                    imageName: "shop_hero"
                ),
                SlideConfiguration(
                    title: "How to Use EzenCook",
                    description: "1. Set your rolling time and rest periods\n2. Choose your sushi style\n3. Start your session and follow the timer",
                    imageName: nil,
                    showsContinue: true,
                    showsPrimaryAction: false,
                    onAppearAction: {
                    }
                ),
                SlideConfiguration(
                    title: "Free vs Premium",
                    description: "Free: Basic timer functionality\nPremium: Advanced features, custom presets, detailed analytics",
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
