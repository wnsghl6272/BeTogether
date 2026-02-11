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
            
            // Tab 2: Similar (New)
            VStack {
                Text("Similar Friends")
                    .font(.btHeader)
                Text("Find people with similar tendencies.")
            }
            .tabItem {
                // "Similar" icon - using sparkles/stack/rectangle
                Image(systemName: "sparkles.rectangle.stack.fill") 
                Text("Similar")
            }
            .tag(1)
            
            // Tab 3: Friends (Was Block)
            VStack {
                Text("Friends")
                    .font(.btHeader)
                Text("Your connected friends list.")
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Friends")
            }
            .tag(2)
            
            // Tab 4: Chat
            VStack {
                Text("Chats")
                    .font(.btHeader)
                Text("No messages yet.")
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Chat")
            }
            .tag(3)
            
            // Tab 5: Profile
            VStack {
                Text("My Profile")
                    .font(.btHeader)
                Text("MBTI: \(userSession.mbtiResult)")
                
                Button("Logout") {
                    userSession.isLoggedIn = false
                    userSession.isOnboardingComplete = false
                    userSession.currentOnboardingStep = .landing
                }
                .padding()
                .background(Color.btTeal)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
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
