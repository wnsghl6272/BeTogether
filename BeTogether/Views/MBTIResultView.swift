import SwiftUI

struct MBTIResultView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var isSaving: Bool = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your Personality Type is")
                .font(.btHeader)
                .foregroundColor(.btDarkGrey)
                
            Text(userSession.mbtiResult)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(.btTeal)
                
            Spacer()
            
            // Buttons
            VStack(spacing: 15) {
                Button(action: {
                    // Reset to Test Intro
                    router.navigate(to: .mbtiTestIntro)
                }) {
                    Text("Test Again")
                        .font(.btButton)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                if isSaving {
                    ProgressView()
                }
                
                Button(action: {
                    isSaving = true
                    Task {
                        do {
                            try await AuthManager.shared.updateUserTraits(data: ["mbti": userSession.mbtiResult])
                            try await AuthManager.shared.updateProfile(data: ["onboarding_step": "personalityQAIntro"])
                            await MainActor.run {
                                isSaving = false
                                router.navigate(to: .personalityQAIntro)
                            }
                        } catch {
                            print("Error saving MBTI result: \(error)")
                            await MainActor.run {
                                isSaving = false
                                router.navigate(to: .personalityQAIntro)
                            }
                        }
                    }
                }) {
                    Text("Continue Registration")
                        .font(.btButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple) // User requested Purple
                        .cornerRadius(12)
                }
                .disabled(isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    let vm = UserSessionViewModel()
    vm.mbtiResult = "ESFP"
    return MBTIResultView()
        .environmentObject(vm)
        .environmentObject(OnboardingRouter())
}
