import SwiftUI

struct NotificationAlertOverlay: View {
    @StateObject private var notifManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            if let alert = notifManager.activeAlert {
                // Dim background
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                
                if alert.isMatchAlert {
                    matchAlertContent(alert)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .zIndex(1)
                } else {
                    likeAlertContent(alert)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: notifManager.activeAlert != nil)
    }
    
    // MARK: - Match Alert (It's a Match!)
    private func matchAlertContent(_ alert: AppNotification) -> some View {
        VStack(spacing: 0) {
            // Confetti-like top accent
            ZStack {
                LinearGradient(
                    colors: [Color.pink, Color.btTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)
                
                VStack(spacing: 4) {
                    Text("💕")
                        .font(.system(size: 40))
                    Text("It's a Match!")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.bottom, -20)
            
            VStack(spacing: 16) {
                // Matched user's photo
                if let matchedUser = alert.matchedUser {
                    matchedProfileView(matchedUser)
                }
                
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 10) {
                    Button(action: {
                        navigateToChat(alert.matchedUser)
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Send a Message")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.btTeal, Color.btTeal.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    
                    Button(action: dismiss) {
                        Text("Keep Exploring")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 4)
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)
            .padding(.bottom, 16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
        }
        .padding(.horizontal, 32)
        .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
    }
    
    private func matchedProfileView(_ matchedUser: MatchedUserInfo) -> some View {
        VStack(spacing: 8) {
            if matchedUser.imageUrl.hasPrefix("http") {
                SimulatorSafeAsyncImage(url: URL(string: matchedUser.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                } errorView: { _ in
                    defaultAvatar
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.pink, .btTeal], startPoint: .top, endPoint: .bottom),
                            lineWidth: 3
                        )
                )
                .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 4)
            } else {
                defaultAvatar
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(colors: [.pink, .btTeal], startPoint: .top, endPoint: .bottom),
                                lineWidth: 3
                            )
                    )
            }
            
            Text(matchedUser.name)
                .font(.title3)
                .fontWeight(.bold)
        }
    }
    
    private var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray4))
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Like Alert (Someone liked you)
    private func likeAlertContent(_ alert: AppNotification) -> some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.headline)
                }
            }
            
            Text(alert.title)
                .font(.title2)
                .fontWeight(.bold)
            
            if alert.isPremiumMockup {
                // Blurred representation
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                        .blur(radius: 8)
                }
                
                Text("???")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Someone liked you!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Button(action: {
                    // Premium Feature Stub
                    dismiss()
                    print("Premium stub: Open See Who Liked Me")
                }) {
                    Text("See who liked me")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.btTeal)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            } else {
                Text(alert.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    private func dismiss() {
        withAnimation {
            notifManager.activeAlert = nil
        }
    }
    
    private func navigateToChat(_ matchedUser: MatchedUserInfo?) {
        dismiss()
        
        guard let matchedUser = matchedUser else { return }
        
        // Navigate to the chat tab with the matched user
        Task {
            if let convId = await ChatManager.findConversationId(partnerId: matchedUser.userId, type: "match") {
                let partner = User(
                    supabaseId: matchedUser.userId,
                    name: matchedUser.name,
                    age: 0,
                    region: "",
                    distance: 0,
                    mbti: "",
                    isOnline: true,
                    isVerified: true,
                    imageName: matchedUser.imageUrl,
                    job: "",
                    height: 0,
                    university: "",
                    drinking: "",
                    smoking: "",
                    oneLineIntro: "",
                    selfIntro: ""
                )
                let session = ChatSession(conversationId: convId, partner: partner, conversationType: "match")
                await MainActor.run {
                    NavigationManager.shared.pendingChatSession = session
                    NavigationManager.shared.selectedTab = 3
                }
            } else {
                // Conversation not created yet — just go to Likes & Matches tab
                await MainActor.run {
                    NavigationManager.shared.selectedTab = 1
                }
            }
        }
    }
}

#Preview {
    NotificationAlertOverlay()
        .onAppear {
            NotificationManager.shared.activeAlert = AppNotification(
                title: "It's a Match! 🎉",
                message: "You and Ji-min liked each other!",
                isPremiumMockup: false,
                isMatchAlert: true,
                matchedUser: MatchedUserInfo(userId: "test", name: "Ji-min", imageUrl: "")
            )
        }
}
