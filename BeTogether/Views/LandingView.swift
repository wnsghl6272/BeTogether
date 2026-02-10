import SwiftUI

struct LandingView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "heart.fill")
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
