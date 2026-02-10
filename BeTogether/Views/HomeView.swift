import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Welcome to BeTogether")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                
                Text("You are all set!")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                
                // Temporary logout for testing
                Button(action: {
                    userSession.isLoggedIn = false
                    userSession.isOnboardingComplete = false
                    userSession.currentOnboardingStep = .landing
                }) {
                    Text("Logout (Debug)")
                        .foregroundColor(.red)
                }
                .padding(.top, 50)
            }
        }
    }
}
