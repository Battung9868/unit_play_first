import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool
    
    
    init(
        title: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isLoading: Bool = false
    ) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("ButtonText")))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(Color("ButtonText"))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color("Button") : Color("Button").opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color("Button").opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct SecondaryButton: View {
    
    
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color("Accent"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("Background"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Accent"), lineWidth: 2)
                        )
                )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct DestructiveButton: View {
    
    
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct IconButton: View {
    
    
    let icon: String
    let action: () -> Void
    let isEnabled: Bool
    let size: CGFloat
    
    
    init(
        icon: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        size: CGFloat = 24
    ) {
        self.icon = icon
        self.action = action
        self.isEnabled = isEnabled
        self.size = size
    }
    
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(isEnabled ? Color("PrimaryText") : Color("SecondaryText"))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color("Background"))
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct FloatingActionButton: View {
    
    
    let icon: String
    let action: () -> Void
    let isEnabled: Bool
    
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color("Accent"))
                        .shadow(color: Color("Accent").opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .disabled(!isEnabled)
        .scaleEffect(isEnabled ? 1.0 : 0.9)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}


#Preview {
    VStack(spacing: 20) {
        PrimaryButton(
            title: "Start Timer",
            action: {},
            isEnabled: true,
            isLoading: false
        )
        
        SecondaryButton(
            title: "Cancel",
            action: {},
            isEnabled: true
        )
        
        DestructiveButton(
            title: "Delete",
            action: {},
            isEnabled: true
        )
        
        HStack(spacing: 20) {
            IconButton(
                icon: "play.fill",
                action: {},
                isEnabled: true
            )
            
            IconButton(
                icon: "pause.fill",
                action: {},
                isEnabled: true
            )
            
            FloatingActionButton(
                icon: "plus",
                action: {},
                isEnabled: true
            )
        }
    }
    .padding()
    .background(Color("Background"))
}

