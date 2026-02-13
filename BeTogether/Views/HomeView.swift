import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    let users: [User] = User.mockUsers
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                // Logo / Brand (Selected State)
                Text("BeTogether")
                    .font(.custom("ArialRoundedMTBold", size: 24))
                    .foregroundColor(.btTeal)
                    .shadow(color: .btTeal.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Center Menu (Dimmed)
                HStack(spacing: 20) {
                    Text("Discover")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 16, weight: .medium))
                    Text("Gathering")
                        .foregroundColor(.gray.opacity(0.6))
                        .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
                
                // Settings Icon
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.btIvory)
            
            // Photo Card List
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(users) { user in
                        PhotoCardView(user: user)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.btIvory)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
}
