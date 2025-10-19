import SwiftUI

public struct OnboardingAssets {
    public static func color(named name: String) -> Color {
        Color(name)
    }
    public static func image(named name: String) -> Image {
        Image(name)
    }
} 