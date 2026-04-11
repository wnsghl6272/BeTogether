import SwiftUI

struct ChatRoomView: View {
    let partner: User
    let conversationId: String
    @StateObject private var chatManager = ChatManager()
    @State private var messageText: String = ""
    @Environment(\.colorScheme) var colorScheme
    @State private var currentUserId: String = ""
    @State private var isFriend: Bool = true // assume friend until checked
    @State private var friendAddStatus: String? = nil
    @State private var showReportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Friend add banner (only if not already friends)
            if !isFriend {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.btTeal)
                    
                    Text("\(partner.name) is not your friend yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let status = friendAddStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Button("Add Friend") {
                            addFriend()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.btTeal)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatManager.messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.sender_id == currentUserId)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatManager.messages.count) { _, _ in
                    if let lastMsg = chatManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // Input Area
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.btTeal)
                        .clipShape(Circle())
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .navigationTitle(partner.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showReportSheet = true }) {
                    Image(systemName: "light.beacon.min.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSubmissionView(targetUserId: partner.id.uuidString, targetUserName: partner.name)
        }
        .onAppear {
            Task {
                if let token = await AuthManager.shared.fetchCurrentAccessToken(),
                   let uid = AiChatInterfaceView.extractSubFromJWT(token) {
                    self.currentUserId = uid
                }
                
                // Check if partner is a friend (check friendships table, not just conversation)
                if let partnerId = partner.supabaseId {
                    let client = AuthManager.shared.client
                    if let token = await AuthManager.shared.fetchCurrentAccessToken(),
                       let uid = await AiChatInterfaceView.extractSubFromJWT(token) {
                        struct FriendCount: Decodable { let count: Int }
                        // Check friendships table in either direction
                        let count: Int = (try? await client.from("friendships")
                            .select("id", head: true, count: .exact)
                            .or("and(user1_id.eq.\(uid),user2_id.eq.\(partnerId)),and(user1_id.eq.\(partnerId),user2_id.eq.\(uid))")
                            .setHeader(name: "Authorization", value: "Bearer \(token)")
                            .execute()
                            .count) ?? 0
                        await MainActor.run {
                            self.isFriend = (count > 0)
                        }
                    }
                }
                
                await chatManager.loadMessages(conversationId: conversationId)
            }
        }
    }
    
    private func sendMessage() {
        let text = messageText
        messageText = "" // clear instantly
        guard let partnerId = partner.supabaseId else { return }
        Task {
            await chatManager.sendMessage(to: partnerId, content: text, conversationId: conversationId)
        }
    }
    
    private func addFriend() {
        guard let nickname = partner.name as String? else { return }
        Task {
            do {
                let success = try await InteractionManager.shared.addFriend(nickname: nickname)
                await MainActor.run {
                    if success {
                        self.friendAddStatus = "Added!"
                        withAnimation(.easeInOut(duration: 0.5).delay(1.5)) {
                            self.isFriend = true
                        }
                    } else {
                        self.friendAddStatus = "Already friends"
                    }
                }
            } catch {
                print("Failed to add friend: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(isCurrentUser ? Color.btTeal : Color(.systemGray5))
                .foregroundColor(isCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 250, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser { Spacer() }
        }
    }
}
