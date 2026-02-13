import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .onAppear {
                        // Use a slightly safer approach for the splash delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                if userSession.isLoggedIn {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    onboardingStepView
                        .transition(.opacity)
                }
            }
        }
        .animation(.default, value: userSession.currentOnboardingStep)
        .animation(.default, value: userSession.isLoggedIn)
        .animation(.default, value: showSplash)
    }
    
    @ViewBuilder
    private var onboardingStepView: some View {
        switch userSession.currentOnboardingStep {
        case .landing:
            LandingView()
        case .phoneInput:
            PhoneInputView()
        case .verification:
            PhoneVerificationView()
        case .notificationPermission:
            NotificationPermissionView()
        case .locationPermission:
            LocationPermissionView()
        case .terms:
            TermsView()
        case .emailInput:
            EmailInputView()
        case .profileSetup:
            ProfileSetupView()
        case .mbtiManualInput:
            MBTIManualInputView()
        case .mbtiTestIntro:
            MBTITestIntroView()
        case .mbtiTest:
            MBTITestView()
        case .mbtiResult:
            MBTIResultView()
        case .personalityQAIntro:
            PersonalityQAIntroView()
        case .personalityQA:
            PersonalityQAView()
        case .matchingPreference:
            MatchingPreferenceView()
        case .contactBlocking:
            ContactBlockingView()
        case .photoUpload:
            PhotoUploadView()
        case .approvalWaiting:
            ApprovalWaitingView()
        case .completed:
            MainTabView()
        }
    }

}

#Preview {
    ContentView()
        .environmentObject(UserSessionViewModel())
}
