import SwiftUI

public struct OnboardingAssets {
    
    
    public static func color(named assetName: String) -> Color {
        Color(assetName)
    }
    
    public static func image(named assetName: String) -> Image {
        Image(assetName)
    }
} 