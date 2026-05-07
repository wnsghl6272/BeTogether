import SwiftUI

struct ExploreView: View {
    @State private var selectedTab = 0
    
    @State private var matchedUsers: [User] = []
    @State private var pendingLikes: [User] = []
    @State private var friends: [User] = []
    
    @State private var isLoading = false
    @State private var friendNickname = ""
    @State private var addFriendStatus: String? = nil
    @State private var showAddFriendSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Tabs", selection: $selectedTab) {
                    Text("Likes & Matches").tag(0)
                    Text("Friends").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    likesAndMatchesTab
                } else {
                    friendsTab
                }
                
                Spacer()
            }
            .navigationTitle("Connections")
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
                let matches = try await InteractionManager.shared.fetchMatches()
                let likes = try await InteractionManager.shared.fetchPendingLikes()
                let friendList = try await InteractionManager.shared.fetchFriends()
                
                await MainActor.run {
                    self.matchedUsers = matches
                    self.pendingLikes = likes
                    self.friends = friendList
                    self.isLoading = false
                }
            } catch {
                print("Error fetching UI data: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    // MARK: - Likes & Matches Tab
    private var likesAndMatchesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                
                // Pending Likes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Who Liked You")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if pendingLikes.isEmpty {
                        Text("No pending likes.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(pendingLikes) { user in
                                    PendingLikeCardView(user: user) { likedUser in
                                        likeBack(user: likedUser)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 10)
                
                // Mutual Matches
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Matches")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else if matchedUsers.isEmpty {
                        Text("No matches yet! Keep swiping and chatting.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(matchedUsers) { user in
                                    MatchCardView(user: user, onUnmatch: {
                                        unmatchUser(user)
                                    })
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private func likeBack(user: User) {
        guard let id = user.supabaseId else { return }
        Task {
            do {
                let isMatch = try await InteractionManager.shared.handleUserAction(targetUserId: id, actionType: "like")
                if isMatch {
                    let matchInfo = MatchedUserInfo(
                        userId: id,
                        name: user.name,
                        imageUrl: user.imageName
                    )
                    await MainActor.run {
                        NotificationManager.shared.showMatchPopupForCurrentUser(matchedUser: matchInfo)
                    }
                }
                // Refresh data because they should move to the Mutual Matches array natively.
                fetchAllData()
            } catch {
                print("Error liking back: \(error)")
            }
        }
    }
    
    // MARK: - Friends Tab
    private var friendsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Add Friend icon
                HStack {
                    Text("My Friends")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddFriendSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                            .foregroundColor(.btTeal)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .frame(maxWidth: .infinity)
                } else if friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No friends yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap the + icon to add friends by nickname")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 12) {
                        ForEach(friends) { friend in
                            FriendRowView(user: friend, onRemove: {
                                removeFriendUser(friend)
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddFriendSheet) {
            AddFriendSheet(
                nickname: $friendNickname,
                status: $addFriendStatus,
                onAdd: { addFriendByNickname() },
                onDismiss: { showAddFriendSheet = false }
            )
            .presentationDetents([.medium])
        }
    }
    
    private func addFriendByNickname() {
        let nickname = friendNickname.trimmingCharacters(in: .whitespaces)
        guard !nickname.isEmpty else { return }
        
        Task {
            do {
                let success = try await InteractionManager.shared.addFriend(nickname: nickname)
                await MainActor.run {
                    if success {
                        self.addFriendStatus = "Successfully added \(nickname) as a friend!"
                        self.friendNickname = ""
                        fetchAllData()
                    } else {
                        self.addFriendStatus = "User not found or already a friend."
                    }
                }
            } catch {
                await MainActor.run {
                    self.addFriendStatus = "Error adding friend: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func unmatchUser(_ user: User) {
        guard let id = user.supabaseId else { return }
        withAnimation { matchedUsers.removeAll { $0.id == user.id } }
        Task {
            do {
                try await InteractionManager.shared.unmatch(targetUserId: id)
                // Refresh from DB to ensure UI is fully in sync
                fetchAllData()
            } catch {
                print("Error unmatching user: \(error)")
                // Re-fetch to restore accurate state since unmatch failed
                fetchAllData()
            }
        }
    }
    
    private func removeFriendUser(_ user: User) {
        guard let id = user.supabaseId else { return }
        withAnimation { friends.removeAll { $0.id == user.id } }
        Task {
            let client = AuthManager.shared.client
            let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
            let _ = try? await client.rpc("remove_friend", params: ["p_target_user_id": id])
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
        }
    }
}

#Preview {
    ExploreView()
}
