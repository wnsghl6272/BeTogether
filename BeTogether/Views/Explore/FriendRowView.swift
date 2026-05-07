import SwiftUI

struct FriendRowView: View {
    let user: User
    var onRemove: (() -> Void)? = nil
    @State private var showRemoveAlert = false
    @State private var showProfileCard = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { showProfileCard = true }) {
                ProfileAvatarView(imageUrl: user.imageName, size: 50)
            }
            .buttonStyle(.plain)
            
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
