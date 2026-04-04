import SwiftUI

struct ChatRoomView: View {
    let partner: User
    @StateObject private var chatManager = ChatManager()
    @State private var messageText: String = ""
    @Environment(\.colorScheme) var colorScheme
    @State private var currentUserId: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
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
                .onChange(of: chatManager.messages.count) { _ in
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
        .onAppear {
            Task {
                if let token = await AuthManager.shared.fetchCurrentAccessToken(),
                   let uid = AiChatInterfaceView.extractSubFromJWT(token) {
                    self.currentUserId = uid
                }
                guard let partnerId = partner.supabaseId else { return }
                await chatManager.loadMessages(partnerId: partnerId)
            }
        }
    }
    
    private func sendMessage() {
        let text = messageText
        messageText = "" // clear instantly
        guard let partnerId = partner.supabaseId else { return }
        Task {
            await chatManager.sendMessage(to: partnerId, content: text)
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
