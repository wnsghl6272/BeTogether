import SwiftUI

enum AuthState: Equatable {
    case unauthenticated
    case checkingOTP
    case onboarding
    case pendingApproval
    case approved
}

enum OnboardingDestination: Hashable {
    case phoneInput
    case verification(String) // phone number
    case notificationPermission
    case locationPermission
    case terms
    case emailInput
    case profileSetup
    case mbtiManualInput
    case mbtiTestIntro
    case mbtiTest
    case mbtiResult
    case personalityQAIntro
    case personalityQA
    case matchingPreference
    case contactBlocking
    case photoUpload
}

@MainActor
class OnboardingRouter: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var isExistingUser: Bool = false
    
    @Published var path = NavigationPath()
    
    func navigate(to destination: OnboardingDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
    
    // Mock for now, until Supabase SDK is fully integrated
    func checkUserExists(phone: String, userSession: UserSessionViewModel) async {
        // TODO: Call Supabase edge function 'check-user-exists'
        self.isExistingUser = false 
        
        userSession.phoneNumber = phone
        navigate(to: .verification(phone))
    }
    
    func handleOTPVerified(status: String) {
        // status could be fetched from `profiles` table
        if status == "approved" {
            self.authState = .approved
        } else if status == "pending_approval" {
            self.authState = .pendingApproval
        } else {
            self.authState = .onboarding
            navigate(to: .notificationPermission)
        }
    }
    
    func finishOnboarding(userSession: UserSessionViewModel) {
        // TODO: Update Supabase `profiles` status to 'pending_approval'
        self.authState = .pendingApproval
        self.popToRoot()
        
        userSession.startMockApprovalProcess()
    }
}
