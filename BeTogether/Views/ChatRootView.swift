import SwiftUI

struct ChatRootView: View {
    @State private var selectedTab = 0
    @State private var matchedUsers: [User] = []
    @State private var friends: [User] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Tabs", selection: $selectedTab) {
                    Text("Matches").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if selectedTab == 0 {
                    ChatUsersListView(users: matchedUsers, emptyMessage: "No matches yet. Keep exploring!")
                } else {
                    ChatUsersListView(users: friends, emptyMessage: "No friends added yet.")
                }
                
                Spacer()
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetchAllData()
            }
        }
    }
    
    private func fetchAllData() {
        isLoading = true
        Task {
            do {
                let fetchedMatches = try await InteractionManager.shared.fetchMatches()
                let fetchedFriends = try await InteractionManager.shared.fetchFriends()
                
                await MainActor.run {
                    self.matchedUsers = fetchedMatches
                    self.friends = fetchedFriends
                    self.isLoading = false
                }
            } catch {
                print("Error fetching UI data: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
}

struct ChatUsersListView: View {
    let users: [User]
    let emptyMessage: String
    
    var body: some View {
        if users.isEmpty {
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            List(users) { user in
                NavigationLink(destination: ChatRoomView(partner: user)) {
                    HStack(spacing: 15) {
                        ProfileAvatarView(imageUrl: user.imageName)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Tap to chat...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
        }
    }
}
