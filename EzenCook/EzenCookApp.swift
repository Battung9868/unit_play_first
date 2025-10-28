import SwiftUI
import StoreKit
import Combine

@main
struct EzenCookApp: App {
    @StateObject private var dataManager = DataManager.shared
    @AppStorage("colorScheme") private var selectedColorScheme: String = "light"
    @AppStorage("hasSeenOnboarding") private var hasCompletedOnboarding = false
    @State private var isMainAppVisible: Bool
    
    init() {
        _isMainAppVisible = State(initialValue: false)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                mainContentView()
                    .opacity(isMainAppVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: isMainAppVisible)
                    .allowsHitTesting(isMainAppVisible)

                if !hasCompletedOnboarding {
                    onboardingView()
                    .opacity(isMainAppVisible ? 0 : 1)
                    .animation(.easeInOut(duration: 0.5), value: isMainAppVisible)
                    .allowsHitTesting(!isMainAppVisible)
                }
            }
            .preferredColorScheme(selectedColorScheme == "dark" ? .dark : .light)
            .environmentObject(dataManager)
            .onAppear {
                bootstrapApplicationContext()
            }
        }
    }
    
    private func mainContentView() -> some View {
        MainCanvas()
            .environmentObject(dataManager)
    }
    
    private func finalizeIntroduction() {
        withAnimation(.easeInOut(duration: 0.5)) {
            isMainAppVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hasCompletedOnboarding = true
        }
    }
    
    private func bootstrapApplicationContext() {
        isMainAppVisible = hasCompletedOnboarding
    }
    
    private func onboardingView() -> some View {
        IntroductionCarousel(
            pages: createOnboardingPages(),
            onFinish: finalizeIntroduction
        )
    }
    
    private func createOnboardingPages() -> [SlideConfiguration] {
        [
            SlideConfiguration(
                title: "Konnichiwa to EzenCook",
                description: "Sushi — on a timer We'll tell you when to remove the rice, add the nori. Customize the steps and save your favorite presets.",
                imageName: "shop_hero"
            ),
            SlideConfiguration(
                title: "How to Use EzenCook",
                description: "1. Set your rolling time, rest time, and number of rolls.\n2. Customize for your sushi style and preparation intensity.\n3. Tap start and begin your sushi session!\n4. After finishing, check your progress and stats in the History tab.",
                imageName: nil,
                showsContinue: true,
                showsPrimaryAction: false
            ),
            SlideConfiguration(
                title: "EzenCook — let's roll",
                description: """
Set the time for one wrap.
1. Pick how many you're making.
2. Tap Roll it! to start.
3. Check your best in Stats.
""",
                imageName: nil,
                showsContinue: true,
                showsPrimaryAction: false,
                showsSecondaryAction: false,
                bottomImageName: "signing"
            )
        ]
    }
}
