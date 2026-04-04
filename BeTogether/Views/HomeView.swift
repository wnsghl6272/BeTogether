import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                // Logo / Brand (Selected State)
                Text("Honsyl")
                    .font(.custom("ArialRoundedMTBold", size: 24))
                    .foregroundColor(.btTeal)
                    .shadow(color: .btTeal.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Alerts Icon
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    // Settings Icon
                    Button(action: {}) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.btIvory)
            
            // AI Chat Interface
            AiChatInterfaceView()
                .padding(.top, 10)
                .background(Color.btIvory)
        }
        .background(Color.btIvory)
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
}
