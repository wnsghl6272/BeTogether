import Foundation
import Supabase
import Combine

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let sender_id: String
    let receiver_id: String
    let content: String
    let created_at: String
}

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    private var channel: RealtimeChannelV2?
    private var currentSubscriptionTask: Task<Void, Never>?
    
    /// Load existing messages for the conversation
    func loadMessages(partnerId: String) async {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = AiChatInterfaceView.extractSubFromJWT(token) else {
            return
        }
        
        do {
            let client = AuthManager.shared.client
            let filter = "and(sender_id.eq.\(currentUserId),receiver_id.eq.\(partnerId)),and(sender_id.eq.\(partnerId),receiver_id.eq.\(currentUserId))"
            
            let fetchedMessages: [ChatMessage] = try await client.from("messages")
                .select()
                .or(filter)
                .order("created_at", ascending: true)
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
                .value
            
            self.messages = fetchedMessages
            
            // Re-subscribe to realtime events exclusively for this session
            await setupRealtime(currentUserId: currentUserId, partnerId: partnerId)
            
        } catch {
            print("Failed to load messages:", error)
        }
    }
    
    func sendMessage(to partnerId: String, content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = AiChatInterfaceView.extractSubFromJWT(token) else {
            return
        }
        
        struct InsertMessage: Encodable {
            let sender_id: String
            let receiver_id: String
            let content: String
        }
        
        let newMessage = InsertMessage(sender_id: currentUserId, receiver_id: partnerId, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
        
        do {
            let client = AuthManager.shared.client
            let insertedMessage: ChatMessage = try await client.from("messages")
                .insert(newMessage)
                .select()
                .single()
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
                .value
            
            // Appends locally to avoid waiting for realtime if possible, or realtime might handle it.
            // Supabase Realtime might duplicate if we manually append. 
            // We append manually since local state changes faster.
            if !self.messages.contains(where: { $0.id == insertedMessage.id }) {
                self.messages.append(insertedMessage)
            }
            
        } catch {
            print("Failed to send message:", error)
        }
    }
    
    private func setupRealtime(currentUserId: String, partnerId: String) async {
        let client = AuthManager.shared.client
        
        // Disconnect old channel if iterating
        if let existingChannel = channel {
            await existingChannel.unsubscribe()
        }
        currentSubscriptionTask?.cancel()
        
        let newChannel = client.realtimeV2.channel("public:messages")
        
        currentSubscriptionTask = Task {
            let stream = newChannel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "messages"
            )
            
            try? await newChannel.subscribeWithError()
            
            for await change in stream {
                let record = change.record
                
                // Manual parse since dictionary
                do {
                    let jsonData = try JSONEncoder().encode(record)
                    let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
                    
                    // Only process messages for this connection
                    let isRelevant = (message.sender_id == currentUserId && message.receiver_id == partnerId) ||
                                     (message.sender_id == partnerId && message.receiver_id == currentUserId)
                    
                    if isRelevant {
                        if !self.messages.contains(where: { $0.id == message.id }) {
                            self.messages.append(message)
                        }
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
