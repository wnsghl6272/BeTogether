import SwiftUI

struct TermsView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var termsAgreed: Bool = false
    @State private var privacyAgreed: Bool = false
    @State private var marketingAgreed: Bool = false
    @State private var isSaving: Bool = false
    
    var allAgreed: Bool {
        return termsAgreed && privacyAgreed
    }
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Terms of Service")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("Please review and agree to our terms.")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        BTCheckBox(isChecked: $termsAgreed)
                        Text("I agree to the Terms of Service")
                            .font(.btBody)
                            .foregroundColor(.black)
                    }
                    
                    HStack {
                        BTCheckBox(isChecked: $privacyAgreed)
                        Text("I agree to the Privacy Policy")
                            .font(.btBody)
                            .foregroundColor(.black)
                    }
                    
                    HStack {
                        BTCheckBox(isChecked: $marketingAgreed)
                        Text("I agree to receive marketing emails (Optional)")
                            .font(.btBody)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 40)
                
                Button(action: {
                    termsAgreed = true
                    privacyAgreed = true
                    marketingAgreed = true
                }) {
                    Text("Agree to All")
                        .font(.btBody)
                        .foregroundColor(.btTeal)
                        .underline()
                }
                
                Spacer()
                
                if isSaving {
                    ProgressView()
                        .padding(.bottom, 10)
                }
                
                BTButton(title: "Next", action: {
                    isSaving = true
                    Task {
                        do {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            let nowString = formatter.string(from: Date())
                            
                            try await AuthManager.shared.updateProfile(data: [
                                "terms_agreed_at": nowString,
                                "onboarding_step": "emailInput"
                            ])
                            await MainActor.run {
                                isSaving = false
                                router.navigate(to: .emailInput)
                            }
                        } catch {
                            print("Error saving terms: \(error)")
                            await MainActor.run {
                                isSaving = false
                                router.navigate(to: .emailInput)
                            }
                        }
                    }
                }, isDisabled: !allAgreed || isSaving)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    TermsView()
        .environmentObject(UserSessionViewModel())
}
