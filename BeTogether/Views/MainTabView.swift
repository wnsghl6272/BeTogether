import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Tab 2: Explore
            MatchesView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)
            
            // Tab 3: Like
            ExploreView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Like")
                }
                .tag(2)
            
            // Tab 4: Chat
            ChatRootView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(3)
            
            // Tab 5: Profile
            ProfileMainView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
                
            // Tab 6: Admin (Hidden)
            if userSession.role == "admin" {
                AdminDashboardView()
                    .tabItem {
                        Image(systemName: "shield.checkerboard")
                        Text("Admin")
                    }
                    .tag(5)
            }
        }
        .accentColor(.btTeal)
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(OnboardingRouter())
}
