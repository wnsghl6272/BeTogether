import Foundation
import Supabase
import Combine
import UserNotifications

struct MatchedUserInfo {
    let userId: String
    let name: String
    let imageUrl: String
}

struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isPremiumMockup: Bool
    var isMatchAlert: Bool = false
    var matchedUser: MatchedUserInfo? = nil
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
            
            if case let .insert(action) = change {
                let dict = action.record
                if let typeValue = dict["type"],
                   case let .string(typeString) = typeValue {
                    
                    if typeString == "new_match" {
                        // Extract the actor_id (the person we matched with)
                        if let actorValue = dict["actor_id"],
                           case let .string(actorId) = actorValue {
                            await handleMatchNotification(actorId: actorId)
                        }
                        
                        self.triggerLocalNotification(title: "It's a Match! 🎉", body: "You and someone special both liked each other!")
                        
                    } else if typeString == "new_like" {
                        await MainActor.run {
                            self.triggerLikePopup()
                        }
                        
                        let msgVal = dict["message"]
                        var bodyMsg = "Someone liked you!"
                        if case let .string(str) = msgVal { bodyMsg = str }
                        
                        self.triggerLocalNotification(title: "New Like!", body: bodyMsg)
                    }
                }
            }
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
    
    // MARK: - Match Handling
    
    /// Fetch matched user profile and show the match popup
    private func handleMatchNotification(actorId: String) async {
        do {
            let matchedUser = try await fetchUserProfile(userId: actorId)
            await MainActor.run {
                self.triggerMatchPopup(matchedUser: matchedUser)
            }
        } catch {
            print("Failed to fetch matched user profile: \(error)")
            // Fallback: show generic match popup
            await MainActor.run {
                self.triggerMatchPopup(matchedUser: MatchedUserInfo(userId: actorId, name: "Your Match", imageUrl: ""))
            }
        }
    }
    
    /// Fetch a single user's profile for the match popup
    private func fetchUserProfile(userId: String) async throws -> MatchedUserInfo {
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        
        struct ProfileResult: Decodable {
            let id: String
            let full_name: String?
            let nickname: String?
        }
        
        let profiles: [ProfileResult] = try await client.from("profiles")
            .select("id, full_name, nickname")
            .eq("id", value: userId)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
        
        let profile = profiles.first
        let name = profile?.full_name ?? profile?.nickname ?? "Your Match"
        
        // Fetch photo
        var imageUrl = ""
        if let photos = try? await AuthManager.shared.fetchUserPhotos(userId: userId),
           let firstPhoto = photos.first {
            imageUrl = firstPhoto.image_url
        }
        
        return MatchedUserInfo(userId: userId, name: name, imageUrl: imageUrl)
    }
    
    /// Show Match popup for the person who triggered the like (caller side)
    func showMatchPopupForCurrentUser(matchedUser: MatchedUserInfo) {
        triggerMatchPopup(matchedUser: matchedUser)
    }
    
    private func triggerMatchPopup(matchedUser: MatchedUserInfo) {
        activeAlert = AppNotification(
            title: "It's a Match! 🎉",
            message: "You and \(matchedUser.name) liked each other!",
            isPremiumMockup: false,
            isMatchAlert: true,
            matchedUser: matchedUser
        )
    }
    
    private func triggerLikePopup() {
        // Create an alert that shows the premium mockup
        activeAlert = AppNotification(
            title: "New Like!",
            message: "Someone liked you.",
            isPremiumMockup: true
        )
    }
    
    private func triggerLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule local notification: \(error)")
            }
        }
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
