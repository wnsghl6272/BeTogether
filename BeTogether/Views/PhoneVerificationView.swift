import SwiftUI

struct PhoneVerificationView: View {
    let phone: String
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var otpCode: String = ""
    @State private var timeRemaining: Int = 180
    @State private var timerRunning: Bool = true
    
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
                
                Text("Enter the code sent to \(phone)")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                BTTextField(placeholder: "000000", text: $otpCode, keyboardType: .numberPad)
                    .padding(.horizontal, 40)
                    .onChange(of: otpCode) { oldValue, newValue in
                        if newValue.count > 6 {
                            otpCode = String(newValue.prefix(6))
                        }
                    }
                
                HStack {
                    Text(timeString(time: timeRemaining))
                        .font(.btBody)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        // Resend Logic
                        timeRemaining = 180
                        timerRunning = true
                    }) {
                        Text("Resend Code")
                            .font(.btBody)
                            .foregroundColor(.btTeal)
                            .underline()
                    }
                }
                .padding(.horizontal, 40)
                
                if let errorMessage = router.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                if router.isExistingUser {
                    Button(action: {
                        router.navigate(to: .emailInput)
                    }) {
                        Text("Get code via email")
                            .font(.btBody)
                            .foregroundColor(.btTeal)
                            .underline()
                    }
                    .padding(.bottom, 10)
                }
                
                BTButton(title: "Verify", action: {
                    userSession.phoneNumber = phone
                    router.errorMessage = nil
                    Task {
                        do {
                            try await AuthManager.shared.verifySMSOTP(phone: phone, token: otpCode)
                            // SDK가 세션(Keychain)을 자동 저장하므로 바로 다음 화면으로 이동
                            await MainActor.run {
                                router.handleOTPVerified(status: "success")
                            }
                        } catch {
                            print("Verification failed: \(error)")
                            await MainActor.run {
                                router.errorMessage = "인증 실패: \(error.localizedDescription)"
                            }
                        }
                    }
                }, isDisabled: otpCode.count != 6)
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
    PhoneVerificationView(phone: "+61412345678")
        .environmentObject(UserSessionViewModel())
}
