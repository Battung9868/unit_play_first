import SwiftUI

struct OnboardingPage: View {
    let model: OnboardingPageModel
    let onContinue: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
            Spacer().frame(height: 50) // Ensures consistent header height for all screens
            if let imageName = model.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150, maxHeight: 150)
                    .padding(.bottom, 8)
            }
            Text(model.title)
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)
                .foregroundColor(Color("PrimaryText"))
            ScrollView(showsIndicators: true) {
                Text(model.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("SecondaryText"))
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: 600)
            Spacer()
                .frame(height: 100)
            if let customContent = model.customContent {
                customContent()
            } else {
                // Notification permission button for onboarding second screen
                if model.showsNotificationButton {
                    Button(action: {
                    }) {
                        Text("Enable Notifications")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("Button"))
                    .padding(.horizontal, 32)
                    Button("Continue") {
                        onContinue?()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    .tint(Color("Button"))
                    .font(.headline)
                }
                // Purchase button for last screen
                else {
                    if model.showsPrimaryAction, let primaryTitle = model.primaryActionTitle, let primaryAction = model.primaryAction {
                        Button(primaryTitle, action: primaryAction)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 32)
                            .tint(Color("Button"))
                            .font(.headline)
                    }
                    if model.showsContinue {
                        Button {
                            onContinue?()
                        } label: {
                                Image("sushi_button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                            
                        }
                    }
                    if model.showsSecondaryAction, let secondaryTitle = model.secondaryActionTitle, let secondaryAction = model.secondaryAction {
                        Button(secondaryTitle, action: secondaryAction)
                            .buttonStyle(.plain)
                            .foregroundColor(Color("Accent"))
                            .padding(.top, 8)
                    }
                    
                }
                Spacer()
            }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
            .background(Color("Background"))
            .ignoresSafeArea()
            .overlay(
                // Bottom right image for specific pages
                Group {
                    if let bottomImageName = model.bottomImageName {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(bottomImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .padding(.trailing, 20)
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                }
            )
        }
        .onAppear {
            model.onAppearAction?()
        }
    }
}

// Preview
struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPage(
            model: OnboardingPageModel(
                title: "Welcome to FastZen",
                description: "Track your fasts, stay motivated, and unlock premium features!",
                imageName: "purchaseview-hero"
            ),
            onContinue: {}
        )
    }
} 
