import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @EnvironmentObject var userSession: UserSessionViewModel
    @StateObject private var router = OnboardingRouter()
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                        }
                    }
            } else {
                if userSession.isLoggedIn || router.authState == .approved {
                    MainTabView()
                        .transition(.opacity)
                } else if router.authState == .pendingApproval {
                    ApprovalWaitingView()
                        .transition(.opacity)
                } else {
                    NavigationStack(path: $router.path) {
                        LandingView()
                            .navigationDestination(for: OnboardingDestination.self) { destination in
                                switch destination {
                                case .phoneInput:
                                    PhoneInputView()
                                case .verification(let phone):
                                    PhoneVerificationView(phone: phone)
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
                                }
                            }
                    }
                    .environmentObject(router)
                    .transition(.opacity)
                }
            }
        }
        .animation(.default, value: router.authState)
        .animation(.default, value: userSession.isLoggedIn)
        .animation(.default, value: showSplash)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSessionViewModel())
}
