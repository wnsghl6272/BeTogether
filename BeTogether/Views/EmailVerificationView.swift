import SwiftUI

struct EmailVerificationView: View {
    let email: String
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var otpCode: String = ""
    @State private var timeRemaining: Int = 180
    @State private var timerRunning: Bool = true
    @State private var isVerifying: Bool = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("Verification Code")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("Enter the code sent to \(email)")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                BTTextField(placeholder: "Enter code", text: $otpCode, keyboardType: .default)
                    .padding(.horizontal, 40)
                    .onChange(of: otpCode) { oldValue, newValue in
                        if newValue.count > 8 {
                            otpCode = String(newValue.prefix(8))
                        }
                    }
                
                HStack {
                    Text(timeString(time: timeRemaining))
                        .font(.btBody)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            try? await AuthManager.shared.sendEmailOTP(email: email)
                            await MainActor.run {
                                timeRemaining = 180
                                timerRunning = true
                            }
                        }
                    }) {
                        Text("Resend Code")
                            .font(.btBody)
                            .foregroundColor(.btTeal)
                            .underline()
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                if isVerifying {
                    ProgressView()
                        .padding(.bottom, 10)
                }
                
                BTButton(title: "Verify", action: {
                    isVerifying = true
                    Task {
                        do {
                            let _ = try await AuthManager.shared.verifyEmailOTP(email: email, token: otpCode)
                            try await AuthManager.shared.updateProfile(data: ["onboarding_step": "profileSetup"])
                            await MainActor.run {
                                isVerifying = false
                                userSession.email = email
                                router.navigate(to: .profileSetup)
                            }
                        } catch {
                            print("Email Verification failed: \(error)")
                            await MainActor.run {
                                isVerifying = false
                                router.errorMessage = "Verification failed: \(error.localizedDescription)"
                            }
                        }
                    }
                }, isDisabled: otpCode.count < 6 || isVerifying)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 && timerRunning {
                timeRemaining -= 1
            } else {
                timerRunning = false
            }
        }
    }
    
    func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    EmailVerificationView(email: "example@gmail.com")
        .environmentObject(UserSessionViewModel())
        .environmentObject(OnboardingRouter())
}
