import SwiftUI

struct PhoneInputView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @State private var phoneNumber: String = ""
    @State private var countryCode: String = "+61"
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("What's your phone number?")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("We need it to verify your account.")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 15) {
                    Text(countryCode)
                        .font(.btButton)
                        .foregroundColor(.btTeal)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    BTTextField(placeholder: "4...", text: $phoneNumber, keyboardType: .numberPad)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                BTButton(title: "Next", action: {
                    userSession.phoneNumber = "\(countryCode)\(phoneNumber)"
                    userSession.advanceToNextStep()
                }, isDisabled: phoneNumber.isEmpty || phoneNumber.count < 9)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    PhoneInputView()
        .environmentObject(UserSessionViewModel())
}
