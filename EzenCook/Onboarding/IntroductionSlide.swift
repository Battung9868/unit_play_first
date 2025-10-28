import SwiftUI

struct IntroductionSlide: View {
    
    
    let pageModel: SlideConfiguration
    
    let onContinue: (() -> Void)?
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
            Spacer().frame(height: 50) // Ensures consistent header height for all screens
            if let imageName = pageModel.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150, maxHeight: 150)
                    .padding(.bottom, 8)
            }
            Text(pageModel.title)
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)
                .foregroundColor(Color("PrimaryText"))
            ScrollView(showsIndicators: true) {
                Text(pageModel.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("SecondaryText"))
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxHeight: 600)
            Spacer()
                .frame(height: 100)
            if let customContent = pageModel.customContent {
                customContent()
            } else {
                if pageModel.showsNotificationButton {
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
                else {
                    if pageModel.showsPrimaryAction, let primaryTitle = pageModel.primaryActionTitle, let primaryAction = pageModel.primaryAction {
                        Button(primaryTitle, action: primaryAction)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .padding(.horizontal, 32)
                            .tint(Color("Button"))
                            .font(.headline)
                    }
                    if pageModel.showsContinue {
                        Button {
                            onContinue?()
                        } label: {
                                Image("action_trigger")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120)
                            
                        }
                    }
                    if pageModel.showsSecondaryAction, let secondaryTitle = pageModel.secondaryActionTitle, let secondaryAction = pageModel.secondaryAction {
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
                Group {
                    if let bottomImageName = pageModel.bottomImageName {
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
            pageModel.onAppearAction?()
        }
    }
}

struct OnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionSlide(
            pageModel: SlideConfiguration(
                title: "Welcome to EzenCook",
                description: "Track your sushi sessions, stay motivated, and unlock premium features!",
                imageName: "shop_hero"
            ),
            onContinue: {}
        )
    }
} 
