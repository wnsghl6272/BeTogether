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
                
                BTTextField(placeholder: "example@gmail.com", text: $email, keyboardType: .emailAddress)
                    .padding(.horizontal, 40)
                

                
                Spacer()
                
                BTButton(title: "Next", action: {
                    userSession.email = email
                    router.navigate(to: .profileSetup)
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
