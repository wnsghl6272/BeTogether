import SwiftUI

struct ApprovalWaitingView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Simple state to rotate loading indicator
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                // Status Icon/Image
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 150, height: 150)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    if userSession.isApproved {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.btTeal)
                    } else if userSession.approvalRejectionReason != nil {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                    } else {
                        // Pending - Loading
                        Image(systemName: "hourglass")
                            .font(.system(size: 60))
                            .foregroundColor(.btTeal)
                            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                            .animation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false), value: isRotating)
                            .onAppear {
                                isRotating = true
                            }
                    }
                }
                .padding(.top, 100)
                
                // Status Text
                VStack(spacing: 15) {
                    if userSession.isApproved {
                        Text("You're Approved!")
                            .font(.btHeader)
                            .foregroundColor(.btTeal)
                        Text("Welcome to BeTogether.\nStart finding your true connection.")
                            .font(.btSubheader)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    } else if let reason = userSession.approvalRejectionReason {
                        Text("Approval Failed")
                            .font(.btHeader)
                            .foregroundColor(.red)
                        Text(reason)
                            .font(.btSubheader)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    } else {
                        Text("Reviewing Profile...")
                            .font(.btHeader)
                            .foregroundColor(.black)
                        Text("We are checking your photos\nto ensure a safe community.")
                            .font(.btSubheader)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Action Button
                if userSession.isApproved {
                    BTButton(title: "Start BeTogether") {
                        userSession.isLoggedIn = true 
                        router.authState = .approved
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                } else if userSession.approvalRejectionReason != nil {
                    BTButton(title: "Upload Photos Again") {
                        router.authState = .onboarding
                        router.navigate(to: .photoUpload)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                } else {
                     // Show nothing or a disabled "Checking..." button
                     Text("Please wait...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            if !userSession.isApproved && userSession.approvalRejectionReason == nil {
                // Ensure the mock process starts if we land here directly (though VM handles it usually)
                // VM calls it on transition, so we might just wait.
            }
        }
    }
}

#Preview {
    ApprovalWaitingView()
        .environmentObject(UserSessionViewModel())
}
