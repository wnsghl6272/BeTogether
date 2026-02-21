import SwiftUI

struct PersonalityQAIntroView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.purple)
                
                Text("My Personality Q&A")
                    .font(.btHeader)
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                
                Text("Answer a few more questions to help us find your perfect match.")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                BTButton(title: "Start Q&A") {
                    router.navigate(to: .personalityQA)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    PersonalityQAIntroView()
        .environmentObject(UserSessionViewModel())
}
