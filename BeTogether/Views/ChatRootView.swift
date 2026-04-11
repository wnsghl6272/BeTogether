import SwiftUI

struct ChatRootView: View {
    @StateObject private var navManager = NavigationManager.shared
    @State private var selectedTab = 0
    @State private var matchedSessions: [ChatSession] = []
    @State private var friendSessions: [ChatSession] = []
    @State private var hasLoadedOnce = false
    @Environment(\.scenePhase) private var scenePhase
    
    // For programmatic navigation
    @State private var navigateToSession: ChatSession? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Hidden NavigationLink for programmatic navigation
                if let session = navigateToSession {
                    NavigationLink(
                        destination: ChatRoomView(partner: session.partner, conversationId: session.conversationId),
                        isActive: Binding(
                            get: { true },
                            set: { if !$0 { navigateToSession = nil } }
                        ),
                        label: { EmptyView() }
                    )
                    .hidden()
                }
                
                VStack {
                    Picker("Tabs", selection: $selectedTab) {
                        Text("Matches").tag(0)
                        Text("Friends").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if !hasLoadedOnce && matchedSessions.isEmpty && friendSessions.isEmpty {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if selectedTab == 0 {
                        ChatUsersListView(sessions: matchedSessions, emptyMessage: "No matches yet. Keep exploring!") { session in
                            handleSessionTap(session)
                        }
                    } else {
                        ChatUsersListView(sessions: friendSessions, emptyMessage: "No friends added yet.") { session in
                            handleSessionTap(session)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetchAllData()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewChatMessage"))) { _ in
                fetchAllData()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    fetchAllData()
                }
            }
            .onChange(of: navManager.pendingChatSession?.conversationId) { _, newId in
                if newId != nil, let session = navManager.pendingChatSession {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.navigateToSession = session
                        navManager.pendingChatSession = nil
                    }
                }
            }
        }
    }
    
    private func handleSessionTap(_ session: ChatSession) {
        Task {
            if let partnerId = session.partner.supabaseId {
                await ChatManager.markMessagesAsRead(partnerId: partnerId)
                if let uid = AuthManager.shared.currentUserId {
                    await NotificationManager.shared.fetchUnreadCount(for: uid)
                }
                NotificationCenter.default.post(name: NSNotification.Name("NewChatMessage"), object: nil)
            }
        }
        navigateToSession = session
    }
    
    private func fetchAllData() {
        Task {
            do {
                let matchSessions = await ChatManager.fetchChatSessions(forType: "match")
                let friendSess = await ChatManager.fetchChatSessions(forType: "friend")
                
                let sum = matchSessions.map({ $0.unreadCount }).reduce(0, +) + friendSess.map({ $0.unreadCount }).reduce(0, +)
                
                await MainActor.run {
                    self.matchedSessions = matchSessions
                    self.friendSessions = friendSess
                    self.hasLoadedOnce = true
                    navManager.unreadChatCount = sum
                }
            }
        }
    }
}

struct ChatUsersListView: View {
    let sessions: [ChatSession]
    let emptyMessage: String
    let onTap: (ChatSession) -> Void
    
    var body: some View {
        if sessions.isEmpty {
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            List(sessions) { session in
                Button(action: {
                    onTap(session)
                }) {
                    HStack(spacing: 15) {
                        ProfileAvatarView(imageUrl: session.partner.imageName, size: 46)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.partner.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(session.lastMessage ?? "Tap to chat...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        if session.unreadCount > 0 {
                            Text("\(session.unreadCount)")
                                .font(.caption).bold()
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.btTeal)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
        }
    }
}
