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
    case emailVerification(String) // email verification
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
    @Published var errorMessage: String? = nil
    
    @Published var path = NavigationPath()
    func navigate(to destination: OnboardingDestination) {
        print("Pre-navigate path count: \(path.count)")
        path.append(destination)
        print("Navigate called. Appended \(destination) to path. New count: \(path.count)")
    }
    
    func popToRoot() {
        print("popToRoot called.")
        path.removeLast(path.count)
    }
    
    func checkUserExists(phone: String, userSession: UserSessionViewModel) async {
        do {
            self.errorMessage = nil
            
            var exists = false
            do {
                exists = try await AuthManager.shared.checkUserExists(phone: phone)
            } catch {
                print("Edge function error (maybe not deployed?): \(error)")
                // We don't fail the whole login just because the check fails
                // Let it proceed to send OTP as a new user by default
            }
            
            do {
                try await AuthManager.shared.sendSMSOTP(phone: phone)
            } catch {
                throw error
            }
            
            userSession.phoneNumber = phone
            self.isExistingUser = exists
            navigate(to: .verification(phone))
        } catch {
            let errStr = String(describing: error)
            print("Error checking user / sending OTP: \(error)")
            await MainActor.run {
                self.errorMessage = "Send Error: \(error.localizedDescription)\nDev: \(errStr)"
            }
        }
    }
    
    func handleOTPVerified(status: String) {
        print("handleOTPVerified called with status: \(status)")
        // status could be fetched from `profiles` table
        if status == "approved" {
            self.authState = .approved
        } else if status == "pending_approval" {
            self.authState = .pendingApproval
        } else {
            print("Calling navigate(to: .notificationPermission) for new user")
            self.navigate(to: .notificationPermission)
        }
    }
    
    func finishOnboarding(userSession: UserSessionViewModel) {
        // TODO: Update Supabase `profiles` status to 'pending_approval'
        self.authState = .pendingApproval
        self.popToRoot()
        
        userSession.startMockApprovalProcess()
    }
}
