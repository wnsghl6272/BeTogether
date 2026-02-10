import SwiftUI

struct MBTITestIntroView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()
                
                Image(systemName: "magnifyingglass.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.btTeal)
                
                VStack(spacing: 16) {
                    Text("Discover your")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    Text("Personality Type")
                        .font(.btHeader)
                        .foregroundColor(.btTeal)
                }
                
                Text("Answer 12 quick questions to find out\nwhich animal represents you best!")
                    .font(.btBody)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                BTButton(title: "Start Test") {
                    userSession.advanceToNextStep()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    MBTITestIntroView()
        .environmentObject(UserSessionViewModel())
}
