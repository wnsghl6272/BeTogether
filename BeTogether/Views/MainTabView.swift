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
            
            // Tab 2: Matches & Chat
            MatchesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Matches")
                }
                .tag(1)
            
            // Tab 3: Explore
            ExploreView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Explore")
                }
                .tag(2)
            
            // Tab 4: Notifications
            NotificationView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Alerts")
                }
                .tag(3)
                .badge(3) // Example badge
            
            // Tab 5: Profile
            ProfileMainView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.btTeal)
    }
}

#Preview {
    MainTabView()
        .environmentObject(UserSessionViewModel())
}
