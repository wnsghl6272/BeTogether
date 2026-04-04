import SwiftUI

struct ExploreView: View {
    @State private var selectedTab = 0
    
    @State private var matchedUsers: [User] = []
    @State private var pendingLikes: [User] = []
    @State private var friends: [User] = []
    
    @State private var isLoading = false
    @State private var friendNickname = ""
    @State private var addFriendStatus: String? = nil
    
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
                                    MatchCardView(user: user)
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
                _ = try await InteractionManager.shared.handleUserAction(targetUserId: id, actionType: "like")
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
            VStack(alignment: .leading, spacing: 20) {
                // Add Friend by Nickname
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Friend by Nickname")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundColor(.gray)
                        TextField("Enter nickname...", text: $friendNickname)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: {
                        addFriendByNickname()
                    }) {
                        Text("Add Friend")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(friendNickname.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.btTeal)
                            .cornerRadius(12)
                    }
                    .disabled(friendNickname.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    if let status = addFriendStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Error") || status.contains("not found") ? .red : .green)
                            .animation(.easeIn, value: addFriendStatus)
                    }
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical, 10)
                
                // Friends List
                VStack(alignment: .leading, spacing: 10) {
                    Text("My Friends")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading...")
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else if friends.isEmpty {
                        Text("You haven't added any friends yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(friends) { friend in
                                FriendRowView(user: friend)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 20)
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
}

// MARK: - Subviews

struct PendingLikeCardView: View {
    let user: User
    let onLikeBack: (User) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ProfileAvatarView(imageUrl: user.imageName)
            
            Text(user.name)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Button("Like Back") {
                onLikeBack(user)
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.pink)
            .cornerRadius(15)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
    }
}

struct MatchCardView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 8) {
            ProfileAvatarView(imageUrl: user.imageName)
                .overlay(Circle().stroke(Color.btTeal, lineWidth: 3))
            
            Text(user.name)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Button("Chat") {
                // Future Implementation
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.btTeal)
            .cornerRadius(15)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
    }
}

struct FriendRowView: View {
    let user: User
    
    var body: some View {
        HStack {
            ProfileAvatarView(imageUrl: user.imageName)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                if !user.job.isEmpty {
                    Text(user.job)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Image(systemName: "message")
                .foregroundColor(.btTeal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileAvatarView: View {
    let imageUrl: String
    
    var body: some View {
        Group {
            if imageUrl.hasPrefix("http") {
                SimulatorSafeAsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                } errorView: { _ in
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                }
            } else {
                Image(imageUrl)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ExploreView()
}
