import SwiftUI

struct EmailInputView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var email: String = ""
    
    var isValidEmail: Bool {
        // Basic email validation
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("What's your email?")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("Please enter a recovery email\nto keep your account safe.")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                BTTextField(placeholder: "example@gmail.com", text: $email, keyboardType: .emailAddress)
                    .padding(.horizontal, 40)
                
                if let errorMessage = router.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                BTButton(title: "Next", action: {
                    Task {
                        do {
                            let exists = try await AuthManager.shared.checkEmailExists(email: email)
                            
                            if exists {
                                await MainActor.run {
                                    router.errorMessage = "This email is already in use."
                                }
                                return
                            }
                            
                            await MainActor.run {
                                userSession.email = email
                            }
                            
                            try await AuthManager.shared.sendEmailOTP(email: email)
                            
                            await MainActor.run {
                                router.errorMessage = nil
                                router.navigate(to: .emailVerification(email))
                            }
                        } catch {
                            print("Failed to check email or send OTP: \(error)")
                            await MainActor.run {
                                router.errorMessage = "Error: \(error.localizedDescription)"
                            }
                        }
                    }
                }, isDisabled: !isValidEmail)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    EmailInputView()
        .environmentObject(UserSessionViewModel())
}
