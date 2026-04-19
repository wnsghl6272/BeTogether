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

// MARK: - Subviews

struct PendingLikeCardView: View {
    let user: User
    let onLikeBack: (User) -> Void
    @State private var isUnlocked = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ProfileAvatarView(imageUrl: user.imageName)
                    .blur(radius: isUnlocked ? 0 : 12)
                    .clipShape(Circle())
                
                Text(isUnlocked ? user.name : "???")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                if isUnlocked {
                    Button("Like Back") {
                        onLikeBack(user)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.pink)
                    .cornerRadius(15)
                } else {
                    Button("Unlock") {
                        withAnimation(.spring()) {
                            isUnlocked = true
                        }
                    }
                    .font(.caption.bold())
                    .foregroundColor(.btTeal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.btTeal, lineWidth: 1))
                }
            }
            
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .shadow(radius: 2)
                    .offset(y: -25)
            }
        }
        .padding(10)
        .frame(width: 130, height: 165)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
    }
}

struct MatchCardView: View {
    let user: User
    var onUnmatch: (() -> Void)? = nil
    @State private var showUnmatchAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            ProfileAvatarView(imageUrl: user.imageName)
                .overlay(Circle().stroke(Color.btTeal, lineWidth: 3))
            
            Text(user.name)
                .font(.subheadline)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Button("Chat") {
                    Task {
                        if let partnerId = user.supabaseId,
                           let convId = await ChatManager.findConversationId(partnerId: partnerId, type: "match") {
                            let session = ChatSession(conversationId: convId, partner: user, conversationType: "match")
                            await MainActor.run {
                                NavigationManager.shared.pendingChatSession = session
                                NavigationManager.shared.selectedTab = 3
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.btTeal)
                .cornerRadius(15)
                
                Menu {
                    Button(role: .destructive) {
                        showUnmatchAlert = true
                    } label: {
                        Label("Unmatch", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
        .alert("Unmatch", isPresented: $showUnmatchAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unmatch", role: .destructive) { onUnmatch?() }
        } message: {
            Text("Are you sure you want to unmatch \(user.name)? This will also delete your chat history.")
        }
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @Binding var nickname: String
    @Binding var status: String?
    let onAdd: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 44))
                        .foregroundColor(.btTeal)
                    Text("Add Friend")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Enter your friend's unique nickname")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                    TextField("Nickname", text: $nickname)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button(action: onAdd) {
                    Text("Add Friend")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nickname.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.btTeal)
                        .cornerRadius(14)
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)
                
                if let status = status {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("Error") || status.contains("not found") ? .red : .green)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}

struct FriendRowView: View {
    let user: User
    var onRemove: (() -> Void)? = nil
    @State private var showRemoveAlert = false
    @State private var showProfileCard = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo — tappable for mini profile
            Button(action: { showProfileCard = true }) {
                ProfileAvatarView(imageUrl: user.imageName, size: 50)
            }
            .buttonStyle(.plain)
            
            // Name + job
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                if !user.job.isEmpty {
                    Text(user.job)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Chat button
            Button(action: {
                Task {
                    if let partnerId = user.supabaseId,
                       let convId = await ChatManager.findConversationId(partnerId: partnerId, type: "friend") {
                        let session = ChatSession(conversationId: convId, partner: user)
                        await MainActor.run {
                            NavigationManager.shared.pendingChatSession = session
                            NavigationManager.shared.selectedTab = 3
                        }
                    }
                }
            }) {
                Image(systemName: "message.fill")
                    .font(.body)
                    .foregroundColor(.btTeal)
                    .padding(8)
                    .background(Color.btTeal.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // More menu (remove friend)
            Menu {
                Button(role: .destructive) {
                    showRemoveAlert = true
                } label: {
                    Label("Remove Friend", systemImage: "person.fill.xmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { onRemove?() }
        } message: {
            Text("Remove \(user.name) from friends? You can re-add them later and your chat history will be preserved.")
        }
        .sheet(isPresented: $showProfileCard) {
            FriendProfileCard(user: user)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Friend Mini Profile Card
struct FriendProfileCard: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            ProfileAvatarView(imageUrl: user.imageName, size: 100)
                .overlay(
                    Circle()
                        .stroke(Color.btTeal, lineWidth: 3)
                )
            
            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if user.age > 0 {
                Text("\(user.age) years old")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Info grid
            HStack(spacing: 24) {
                if !user.job.isEmpty {
                    VStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.btTeal)
                        Text(user.job)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if user.height > 0 {
                    VStack {
                        Image(systemName: "ruler")
                            .foregroundColor(.btTeal)
                        Text("\(user.height)cm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                if user.mbti != "N/A" {
                    VStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.btTeal)
                        Text(user.mbti)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Chat button
            Button(action: {
                dismiss()
                Task {
                    if let partnerId = user.supabaseId,
                       let convId = await ChatManager.findConversationId(partnerId: partnerId, type: "friend") {
                        let session = ChatSession(conversationId: convId, partner: user)
                        await MainActor.run {
                            NavigationManager.shared.pendingChatSession = session
                            NavigationManager.shared.selectedTab = 3
                        }
                    }
                }
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Send Message")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.btTeal)
                .cornerRadius(14)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct ProfileAvatarView: View {
    let imageUrl: String
    var size: CGFloat = 80
    
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
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ExploreView()
}
