import SwiftUI

struct MatchCardView: View {
    let user: User
    var onUnmatch: (() -> Void)? = nil
    @State private var showUnmatchAlert = false
    @State private var showProfileCard = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { showProfileCard = true }) {
                ProfileAvatarView(imageUrl: user.imageName)
                    .overlay(Circle().stroke(Color.btTeal, lineWidth: 3))
            }
            .buttonStyle(.plain)
            
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
        .sheet(isPresented: $showProfileCard) {
            FriendProfileCard(user: user)
                .presentationDetents([.medium])
        }
    }
}
