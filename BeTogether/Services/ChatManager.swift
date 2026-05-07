import Foundation
import Supabase
import Combine

struct ChatSession: Identifiable, Equatable {
    var id: String { conversationId }
    let conversationId: String
    let partner: User
    var conversationType: String = "friend"
    var lastMessage: String?
    var unreadCount: Int = 0
    var clearedAt: String?
    
    static func == (lhs: ChatSession, rhs: ChatSession) -> Bool {
        return lhs.conversationId == rhs.conversationId && lhs.lastMessage == rhs.lastMessage && lhs.unreadCount == rhs.unreadCount && lhs.clearedAt == rhs.clearedAt
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let sender_id: String
    let receiver_id: String
    let content: String
    let created_at: String
    let conversation_id: String?
}

@MainActor
class ChatManager: ObservableObject {
    
    // MARK: - Conversation-based session fetching
    
    struct ConversationRow: Decodable {
        let conversation_id: String
        let partner_id: String
        let partner_full_name: String?
        let partner_nickname: String?
        let partner_occupation: String?
        let partner_birth_date: String?
        let partner_height: String?
        let last_message: String?
        let last_message_at: String?
        let unread_count: Int
        let cleared_at: String?
    }
    
    static func fetchChatSessions(forType type: String) async -> [ChatSession] {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken() else { return [] }
        
        let client = AuthManager.shared.client
        
        do {
            struct ConvTypeParam: Encodable { let conv_type: String }
            let rows: [ConversationRow] = try await client.rpc("get_my_conversations", params: ConvTypeParam(conv_type: type))
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
                .value
            
            var sessions: [ChatSession] = []
            for row in rows {
                // Fetch photo for partner
                var fetchedImageName = "profile_korean_1"
                if let userPhotos = try? await AuthManager.shared.fetchUserPhotos(userId: row.partner_id), let firstPhoto = userPhotos.first {
                    fetchedImageName = firstPhoto.image_url
                }
                
                let birthYearString = String((row.partner_birth_date ?? "").prefix(4))
                let birthYear = Int(birthYearString) ?? 2000
                let currentYear = Calendar.current.component(.year, from: Date())
                let calculatedAge = currentYear - birthYear
                
                let partner = User(
                    supabaseId: row.partner_id,
                    name: row.partner_full_name ?? row.partner_nickname ?? "Unknown",
                    age: calculatedAge,
                    region: type == "match" ? "Matched" : "Friend",
                    distance: 0,
                    mbti: "N/A",
                    isOnline: true,
                    isVerified: true,
                    imageName: fetchedImageName,
                    job: row.partner_occupation ?? "",
                    height: Int(row.partner_height ?? "0") ?? 0,
                    university: "",
                    drinking: "",
                    smoking: "",
                    oneLineIntro: "",
                    selfIntro: "",
                    imageNames: [fetchedImageName]
                )
                
                let session = ChatSession(
                    conversationId: row.conversation_id,
                    partner: partner,
                    conversationType: type,
                    lastMessage: row.last_message,
                    unreadCount: row.unread_count,
                    clearedAt: row.cleared_at
                )
                sessions.append(session)
            }
            return sessions
        } catch {
            print("fetchChatSessions error: \(error)")
            return []
        }
    }
    
    /// Find conversation_id between current user and partner
    static func findConversationId(partnerId: String, type: String) async -> String? {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let partnerUUID = UUID(uuidString: partnerId) else { return nil }
        
        let client = AuthManager.shared.client
        do {
            struct FindConvParams: Encodable {
                let partner_uid: UUID
                let conv_type: String
            }
            let result: String? = try await client.rpc("find_conversation", params: FindConvParams(partner_uid: partnerUUID, conv_type: type))
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
                .value
            return result
        } catch {
            print("findConversationId error: \(error)")
            return nil
        }
    }
    
    static func markMessagesAsRead(partnerId: String) async {
        guard let currentUserId = AuthManager.shared.currentUserId else { return }
        do {
            let client = AuthManager.shared.client
            try await client.from("notifications")
                .update(["is_read": true, "is_seen": true])
                .eq("user_id", value: currentUserId)
                .eq("actor_id", value: partnerId)
                .eq("type", value: "message")
                .execute()
        } catch {
            print("Failed to mark messages as read: \(error)")
        }
    }
    
    static func clearConversation(_ conversationId: String) async {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let uuid = UUID(uuidString: conversationId) else { return }
        let client = AuthManager.shared.client
        do {
            struct ClearParam: Encodable { let conv_id: UUID }
            try await client.rpc("clear_conversation", params: ClearParam(conv_id: uuid))
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
        } catch {
            print("Failed to clear conversation: \(error)")
        }
    }
    
    // MARK: - Instance properties for active chat room
    
    @Published var messages: [ChatMessage] = []
    
    private var channel: RealtimeChannelV2?
    private var currentSubscriptionTask: Task<Void, Never>?
    
    /// Load existing messages for a conversation
    func loadMessages(conversationId: String) async {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = AiRecommendationService.extractSubFromJWT(token) else {
            return
        }
        
        do {
            let client = AuthManager.shared.client
            
            struct Param: Encodable { let conv_id: UUID }
            if let uuid = UUID(uuidString: conversationId) {
                let fetchedMessages: [ChatMessage] = try await client.rpc("get_conversation_messages", params: Param(conv_id: uuid))
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                    .value
                
                self.messages = fetchedMessages
            }
            
            // Subscribe to realtime events for this conversation
            await setupRealtime(conversationId: conversationId, currentUserId: currentUserId)
            
        } catch {
            print("Failed to load messages:", error)
        }
    }
    
    func sendMessage(to partnerId: String, content: String, conversationId: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = AiRecommendationService.extractSubFromJWT(token) else {
            return
        }
        
        struct InsertMessage: Encodable {
            let sender_id: String
            let receiver_id: String
            let content: String
            let conversation_id: String
        }
        
        let newMessage = InsertMessage(
            sender_id: currentUserId,
            receiver_id: partnerId,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            conversation_id: conversationId
        )
        
        do {
            let client = AuthManager.shared.client
            let insertedMessage: ChatMessage = try await client.from("messages")
                .insert(newMessage)
                .select()
                .single()
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
                .value
            
            if !self.messages.contains(where: { $0.id == insertedMessage.id }) {
                self.messages.append(insertedMessage)
            }
            
        } catch {
            print("Failed to send message:", error)
        }
    }
    
    private func setupRealtime(conversationId: String, currentUserId: String) async {
        let client = AuthManager.shared.client
        
        if let existingChannel = channel {
            await existingChannel.unsubscribe()
        }
        currentSubscriptionTask?.cancel()
        
        let newChannel = client.realtimeV2.channel("conv:\(conversationId)")
        
        currentSubscriptionTask = Task {
            let stream = newChannel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages",
                filter: "conversation_id=eq.\(conversationId)"
            )
            
            try? await newChannel.subscribeWithError()
            
            for await change in stream {
                let record = change.record
                
                do {
                    let jsonData = try JSONEncoder().encode(record)
                    let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
                    
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                    }
                } catch {
                    print("Could not decode incoming realtime message", error)
                }
            }
        }
        self.channel = newChannel
    }
    
    deinit {
        currentSubscriptionTask?.cancel()
        if let chan = channel {
            Task { await chan.unsubscribe() }
        }
    }
}
