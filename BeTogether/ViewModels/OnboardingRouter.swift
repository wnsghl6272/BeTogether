import SwiftUI

enum AuthState: Equatable {
    case unauthenticated
    case checkingOTP
    case onboarding
    case pendingApproval
    case approved
    case rejected
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
    
    func handleOTPVerified(status: String, step: String?, role: String = "user") {
        print("handleOTPVerified called with status: \(status), step: \(step ?? "nil"), role: \(role)")
        // status could be fetched from `profiles` table
        if status == "approved" || role == "admin" {
            self.authState = .approved
        } else if status == "pending_approval" {
        } else if status == "rejected" {
            self.authState = .rejected
        } else {
            if let step = step, !step.isEmpty {
                restoreOnboardingState(from: step)
            } else {
                print("Calling navigate(to: .notificationPermission) for new user")
                self.navigate(to: .notificationPermission)
            }
        }
    }
    
    private func restoreOnboardingState(from step: String) {
        print("Restoring state to: \(step)")
        self.popToRoot() // start clean
        
        switch step {
        case "notificationPermission": navigate(to: .notificationPermission)
        case "locationPermission": navigate(to: .locationPermission)
        case "terms": navigate(to: .terms)
        case "emailInput": navigate(to: .emailInput)
        case "profileSetup": navigate(to: .profileSetup)
        case "mbtiManualInput": navigate(to: .mbtiManualInput)
        case "mbtiTestIntro": navigate(to: .mbtiTestIntro)
        case "mbtiTest": navigate(to: .mbtiTest)
        case "mbtiResult": navigate(to: .mbtiResult)
        case "personalityQAIntro": navigate(to: .personalityQAIntro)
        case "personalityQA": navigate(to: .personalityQA)
        case "matchingPreference": navigate(to: .matchingPreference)
        case "contactBlocking": navigate(to: .contactBlocking)
        case "photoUpload": navigate(to: .photoUpload)
        default:
            navigate(to: .notificationPermission)
        }
    }
    
    func finishOnboarding(userSession: UserSessionViewModel) {
        // TODO: Update Supabase `profiles` status to 'pending_approval'
        self.authState = .pendingApproval
        self.popToRoot()
        
        userSession.startMockApprovalProcess()
    }
    
    func initializeSession(userSession: UserSessionViewModel) async {
        do {
            let session = try await AuthManager.shared.client.auth.session
            let accessToken = session.accessToken
            let profileData = await AuthManager.shared.fetchProfileData(accessToken: accessToken)
            await MainActor.run {
                userSession.role = profileData.role
                if profileData.status == "approved" {
                    userSession.isLoggedIn = true
                    self.authState = .approved
                } else if profileData.status == "pending_approval" {
                    self.authState = .pendingApproval
                } else if profileData.status == "rejected" {
                    self.authState = .rejected
                } else {
                    self.authState = .onboarding
                    if let step = profileData.onboardingStep, !step.isEmpty {
                        self.handleOTPVerified(status: profileData.status, step: profileData.onboardingStep)
                    }
                }
            }
        } catch {
            print("No valid session on launch: \(error)")
            await MainActor.run {
                self.authState = .unauthenticated
                userSession.isLoggedIn = false
            }
        }
    }
}
