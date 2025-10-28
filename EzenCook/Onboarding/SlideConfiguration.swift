import SwiftUI

struct SlideConfiguration: Identifiable {
    
    
    let id = UUID()
    
    let title: String
    
    let description: String
    
    let imageName: String?
    
    let showsContinue: Bool
    
    let showsPrimaryAction: Bool
    
    let primaryActionTitle: String?
    
    let primaryAction: (() -> Void)?
    
    let showsSecondaryAction: Bool
    
    let secondaryActionTitle: String?
    
    let secondaryAction: (() -> Void)?
    
    let backgroundColor: Color?
    
    let onAppearAction: (() -> Void)?
    
    let customContent: (() -> AnyView)?
    
    let notificationPermissionResult: ((Bool) -> Void)?
    
    let showsNotificationButton: Bool
    
    let bottomImageName: String?
    
    
    init(title: String,
         description: String,
         imageName: String? = nil,
         showsContinue: Bool = true,
         showsPrimaryAction: Bool = false,
         primaryActionTitle: String? = nil,
         primaryAction: (() -> Void)? = nil,
         showsSecondaryAction: Bool = false,
         secondaryActionTitle: String? = nil,
         secondaryAction: (() -> Void)? = nil,
         backgroundColor: Color? = nil,
         onAppearAction: (() -> Void)? = nil,
         customContent: (() -> AnyView)? = nil,
         notificationPermissionResult: ((Bool) -> Void)? = nil,
         showsNotificationButton: Bool = false,
         bottomImageName: String? = nil) {
        self.title = title
        self.description = description
        self.imageName = imageName
        self.showsContinue = showsContinue
        self.showsPrimaryAction = showsPrimaryAction
        self.primaryActionTitle = primaryActionTitle
        self.primaryAction = primaryAction
        self.showsSecondaryAction = showsSecondaryAction
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryAction = secondaryAction
        self.backgroundColor = backgroundColor
        self.onAppearAction = onAppearAction
        self.customContent = customContent
        self.notificationPermissionResult = notificationPermissionResult
        self.showsNotificationButton = showsNotificationButton
        self.bottomImageName = bottomImageName
    }
} 