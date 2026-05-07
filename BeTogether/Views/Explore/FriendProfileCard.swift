import SwiftUI

struct FriendProfileCard: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            Button(action: { showFullScreen = true }) {
                ProfileAvatarView(imageUrl: user.imageName, size: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.btTeal, lineWidth: 3)
                    )
            }
            .buttonStyle(.plain)
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenImageView(imageUrl: user.imageName)
            }
            
            Text(user.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if user.age > 0 {
                Text("\(user.age) years old")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
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
