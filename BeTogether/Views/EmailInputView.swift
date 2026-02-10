import SwiftUI

struct EmailInputView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
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
                
                BTTextField(placeholder: "example@gmail.com", text: $email, keyboardType: .emailAddress)
                    .padding(.horizontal, 40)
                
                // Social Login Placeholders
                VStack(spacing: 15) {
                    Button(action: {
                        // Apple Login Logic
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Sign in with Apple")
                        }
                        .font(.btButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Google Login Logic
                    }) {
                        HStack {
                            Image(systemName: "globe") // Placeholder for Google G
                            Text("Sign in with Google")
                        }
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
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                BTButton(title: "Next", action: {
                    userSession.email = email
                    userSession.advanceToNextStep()
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
