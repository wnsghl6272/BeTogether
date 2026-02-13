import SwiftUI
import Combine

class UserSessionViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var currentOnboardingStep: OnboardingStep = .landing
    
    // User Data
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var nickname: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: String = ""
    @Published var occupation: String = ""
    @Published var height: String = ""
    @Published var university: String = ""
    @Published var drinking: String = ""
    @Published var smoking: String = ""
    @Published var oneLineIntro: String = "" // New
    @Published var selfIntro: String = ""    // New
    
    // MBTI Data
    @Published var mbtiResult: String = "" // e.g. "ESFP"
    
    // Matching Preferences
    @Published var preferredGender: String = ""
    @Published var minAge: Double = 20
    @Published var maxAge: Double = 35
    @Published var maxDistance: Double = 10
    @Published var filterSmoking: Bool = false
    @Published var filterDrinking: Bool = false
    @Published var filterMBTI: [String] = []
    
    enum OnboardingStep {
        case landing
        case phoneInput
        case verification
        case notificationPermission // New
        case locationPermission     // New
        case terms
        case emailInput
        case profileSetup
        case mbtiManualInput
        case mbtiTestIntro
        case mbtiTest
        case mbtiResult
        case personalityQAIntro
        case personalityQA
        case matchingPreference     // New
        case contactBlocking
        case photoUpload
        case approvalWaiting
        case completed
    }
    
    // Approval Status
    @Published var isApproved: Bool = false
    @Published var approvalRejectionReason: String? = nil
    
    func advanceToNextStep() {
        switch currentOnboardingStep {
        case .landing:
            currentOnboardingStep = .phoneInput
        case .phoneInput:
            currentOnboardingStep = .verification
        case .verification:
            currentOnboardingStep = .notificationPermission
        case .notificationPermission:
            currentOnboardingStep = .locationPermission
        case .locationPermission:
            currentOnboardingStep = .terms
            // Previously verification -> terms. Now verification -> noti -> loc -> terms.
            // User requested "Email Auth Page Maintain". Usually Terms -> Email.
        case .terms:
            currentOnboardingStep = .emailInput
        case .emailInput:
            currentOnboardingStep = .profileSetup
        case .profileSetup:
            currentOnboardingStep = .mbtiManualInput
        case .mbtiManualInput:
            // Default next from manual is result if valid, or test intro if "don't know"
            currentOnboardingStep = .mbtiResult
        case .mbtiTestIntro:
            currentOnboardingStep = .mbtiTest
        case .mbtiTest:
            currentOnboardingStep = .mbtiResult
        case .mbtiResult:
            currentOnboardingStep = .personalityQAIntro
        case .personalityQAIntro:
            currentOnboardingStep = .personalityQA
        case .personalityQA:
            currentOnboardingStep = .matchingPreference
        case .matchingPreference:
            currentOnboardingStep = .contactBlocking
        case .contactBlocking:
            currentOnboardingStep = .photoUpload
        case .photoUpload:
            currentOnboardingStep = .approvalWaiting
            startMockApprovalProcess()
        case .approvalWaiting:
            if isApproved {
                isOnboardingComplete = true
                isLoggedIn = true
                currentOnboardingStep = .completed
            }
        case .completed:
            break
        }
    }
    
    // Mock Approval Process
    func startMockApprovalProcess() {
        isApproved = false
        approvalRejectionReason = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let random = Int.random(in: 1...10)
            if random > 3 {
                self.isApproved = true
            } else {
                self.isApproved = false
                self.approvalRejectionReason = "Face not clearly visible. Please upload clear headshots."
            }
        }
    }
    
    // Explicit jump for "Don't know my MBTI"
    func startMBTITest() {
        currentOnboardingStep = .mbtiTestIntro
    }
    
    // Explicit jump for "Complete Setup" from manual input
    func completeMBTI(with result: String) {
        mbtiResult = result
        currentOnboardingStep = .mbtiResult
    }
}
