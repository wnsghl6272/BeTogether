import SwiftUI

struct LandingView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        userSession.isLoggedIn = true
                        userSession.isOnboardingComplete = true
                        userSession.currentOnboardingStep = .completed
                    }) {
                        Text("Debug: Go to Home")
                            .font(.caption)
                            .padding(8)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .padding(.top, 50)
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                Image(systemName: "heart.fill")
                // ... remaining content ...
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.btTeal)
                    .padding(.bottom, 20)
                
                Text("Find True Connection")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("Your journey with BeTogether begins now")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                BTButton(title: "Start") {
                    withAnimation {
                        userSession.advanceToNextStep()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    LandingView()
        .environmentObject(UserSessionViewModel())
}
