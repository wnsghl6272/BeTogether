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
    @Published var university: String = "" // Added university
    @Published var drinking: String = ""   // Added drinking (e.g. "Non-drinker")
    @Published var smoking: String = ""    // Added smoking (e.g. "Non-smoker")
    
    // MBTI Data
    @Published var mbtiResult: String = "" // e.g. "ESFP"
    
    enum OnboardingStep {
        case landing
        case phoneInput
        case verification
        case terms
        case emailInput
        case profileSetup
        case mbtiManualInput // New step
        case mbtiTestIntro   // New step
        case mbtiTest        // New step
        case mbtiResult      // New step
        case personalityQAIntro // New step
        case personalityQA      // New step
        case contactBlocking    // New step
        case completed
    }
    
    func advanceToNextStep() {
        switch currentOnboardingStep {
        case .landing:
            currentOnboardingStep = .phoneInput
        case .phoneInput:
            currentOnboardingStep = .verification
        case .verification:
            currentOnboardingStep = .terms
        case .terms:
            currentOnboardingStep = .emailInput
        case .emailInput:
            currentOnboardingStep = .profileSetup
        case .profileSetup:
            // After basic profile, go to MBTI
            currentOnboardingStep = .mbtiManualInput
        case .mbtiManualInput:
             // If user entered manually or skipped to test, logic handles it.
             // Default next from manual is result if valid, or test intro if "don't know"
            currentOnboardingStep = .mbtiResult
        case .mbtiTestIntro:
            currentOnboardingStep = .mbtiTest
        case .mbtiTest:
            currentOnboardingStep = .mbtiResult
        case .mbtiResult:
            // Go to Personality Q&A Intro instead of completing immediately
            currentOnboardingStep = .personalityQAIntro
        case .personalityQAIntro:
            currentOnboardingStep = .personalityQA
        case .personalityQA:
            currentOnboardingStep = .contactBlocking
        case .contactBlocking:
            isOnboardingComplete = true
            isLoggedIn = true
            currentOnboardingStep = .completed
        case .completed:
            break
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
