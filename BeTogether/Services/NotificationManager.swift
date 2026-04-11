import Foundation
import Supabase
import Combine

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isPremiumMockup: Bool
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var activeAlert: AppNotification? = nil
    
    // For badge counter
    @Published var unreadCount: Int = 0
    
    private var channel: RealtimeChannelV2?
    private let client = AuthManager.shared.client
    
    private init() {}
    
    private var subscriptionTask: Task<Void, Never>?
    private var currentUserId: String?

func setupRealtime(for userId: String) {
    self.currentUserId = userId
    subscriptionTask?.cancel()
    let channelTask = Task {
        // Clean up previous channel if any
        await channel?.unsubscribe()
        let newChannel = client.realtimeV2.channel("user_notifications_\(userId)")
        self.channel = newChannel
        
        let stream = newChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "notifications",
            filter: "user_id=eq.\(userId)"
        )
        
        try? await newChannel.subscribeWithError()
        
        for await change in stream {
            // New notification occurred
            await fetchUnreadCount(for: userId)
            NotificationCenter.default.post(name: NSNotification.Name("NewChatMessage"), object: nil)
        }
    }
    subscriptionTask = channelTask
}

/// Called when app returns to foreground to recover from network drops
func reconnectIfNeeded() {
    guard let userId = currentUserId else { return }
    setupRealtime(for: userId)
    Task { await fetchUnreadCount(for: userId) }
}

func resetUnread() {
        unreadCount = 0
    }
    
    private func triggerLikePopup() {
        // Create an alert that shows the premium mockup
        activeAlert = AppNotification(
            title: "New Like!",
            message: "Someone liked you.",
            isPremiumMockup: true
        )
    }
    
    func fetchUnreadCount(for userId: String) async {
        do {
            struct NotificationCount: Codable { let id: UUID }
            let items: [NotificationCount] = try await client
                .from("notifications")
                .select("id")
                .eq("user_id", value: userId)
                .eq("is_seen", value: false)
                .execute()
                .value
                
            await MainActor.run {
                self.unreadCount = items.count
            }
        } catch {
            print("Failed to fetch unread count")
        }
    }
}
