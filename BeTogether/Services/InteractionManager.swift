import Foundation
import Supabase

class InteractionManager {
    static let shared = InteractionManager()
    
    private init() {}
    
    /// Records a user action (like, pass, super_like) into the `user_interactions` table
    /// Returns `true` if a match was created (mutual like).
    func handleUserAction(targetUserId: String, actionType: String) async throws -> Bool {
        guard let targetUUID = UUID(uuidString: targetUserId) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid target user ID"])
        }
        
        struct ActionParams: Encodable {
            let target_user_id: UUID
            let action_type: String
        }
        
        let client = AuthManager.shared.client
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        
        let response: Bool = try await client.rpc("handle_user_action", params: ActionParams(target_user_id: targetUUID, action_type: actionType))
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
            .value
        return response
    }
    
    /// Fetches all matched users for the current authenticated user
    func fetchMatches() async throws -> [User] {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = await AiChatInterfaceView.extractSubFromJWT(token),
              let _ = UUID(uuidString: currentUserId) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let client = AuthManager.shared.client
        
        // Let's create an RPC or use pure query
        // The policies allow select on matches where auth.uid() in (user1_id, user2_id)
        // For simplicity we will query Matches table.
        // select: *, user1_id:profiles!matches_user1_id_fkey(*), user2_id:profiles!matches_user2_id_fkey(*)
        
        struct MatchResult: Decodable {
            let user1_id: String
            let user2_id: String
            let user1: UserProfile?
            let user2: UserProfile?
            
            struct UserProfile: Decodable {
                let id: String
                let nickname: String?
                let birth_date: String?
                let occupation: String?
                let height: String?
            }
        }
        
        // This is a complex query, we can query both sides separately or just get matches and then manually fetch profiles
        // We will do a manual fetch for safety
        
        struct BasicMatch: Decodable {
            let user1_id: String
            let user2_id: String
        }
        

        let matches: [BasicMatch] = try await client.from("matches")
            .select("user1_id, user2_id")
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
            .value
            
        var friendIds: [String] = []
        for m in matches {
            if m.user1_id == currentUserId {
                friendIds.append(m.user2_id)
            } else if m.user2_id == currentUserId {
                friendIds.append(m.user1_id)
            }
        }
        
        if friendIds.isEmpty {
            return []
        }
        
        // Fetch profiles for friends
        struct ProfileResponse: Decodable {
            let id: String
            let nickname: String?
            let birth_date: String?
            let occupation: String?
            let height: String?
        }
        
        // In query: in("id", friendIds)
        let profiles: [ProfileResponse] = try await client.from("profiles")
            .select("id, nickname, birth_date, occupation, height")
            .in("id", values: friendIds)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
            
        var matchedUsers: [User] = []
        
        for p in profiles {
            // Re-use logic for photo fetch and age calculation
            var fetchedImageName = "profile_korean_1"
            if let userPhotos = try? await AuthManager.shared.fetchUserPhotos(userId: p.id), let firstPhoto = userPhotos.first {
                fetchedImageName = firstPhoto.image_url
            }
            
            let birthYearString = String((p.birth_date ?? "").prefix(4))
            let birthYear = Int(birthYearString) ?? 2000
            let currentYear = Calendar.current.component(.year, from: Date())
            let calculatedAge = currentYear - birthYear

            let newUser = User(
                supabaseId: p.id,
                name: p.nickname ?? "Unknown",
                age: calculatedAge,
                region: "Matched",
                distance: 0,
                mbti: "N/A",
                isOnline: true,
                isVerified: true,
                imageName: fetchedImageName,
                job: p.occupation ?? "Not specified",
                height: Int(p.height ?? "0") ?? 0,
                university: "",
                drinking: "",
                smoking: "",
                oneLineIntro: "We are matched!",
                selfIntro: "Let's be friends.",
                imageNames: [fetchedImageName]
            )
            matchedUsers.append(newUser)
        }
        
        return matchedUsers
    }

    /// Fetches a user ID specifically by their nickname to support "Add Friend by Nickname"
    func fetchUserByNickname(_ nickname: String) async throws -> String? {
        let client = AuthManager.shared.client
        
        struct ProfileIdResult: Decodable {
            let id: String
        }
        
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        let result: [ProfileIdResult] = try await client.from("profiles")
            .select("id")
            .eq("nickname", value: nickname)
            .limit(1)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
            .value
            
        return result.first?.id
    }
    
    /// Adds a friend by their nickname via RPC
    func addFriend(nickname: String) async throws -> Bool {
        let client = AuthManager.shared.client
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        struct AddFriendParams: Encodable {
            let target_nickname: String
        }
        
        let success: Bool = try await client.rpc("add_friend_by_nickname", params: AddFriendParams(target_nickname: nickname))
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
            .value
        
        return success
    }

    /// Helper to convert a raw Profile DB response to a `User` model array
    private func convertProfilesToUsers(_ profiles: [ProfileResponse], defaultStatus: String) async -> [User] {
        var users: [User] = []
        for p in profiles {
            var fetchedImageName = "profile_korean_1"
            if let userPhotos = try? await AuthManager.shared.fetchUserPhotos(userId: p.id), let firstPhoto = userPhotos.first {
                fetchedImageName = firstPhoto.image_url
            }
            
            let birthYearString = String((p.birth_date ?? "").prefix(4))
            let birthYear = Int(birthYearString) ?? 2000
            let currentYear = Calendar.current.component(.year, from: Date())
            let calculatedAge = currentYear - birthYear

            let newUser = User(
                supabaseId: p.id,
                name: p.nickname ?? "Unknown",
                age: calculatedAge,
                region: "App User",
                distance: 0,
                mbti: "N/A",
                isOnline: true,
                isVerified: true,
                imageName: fetchedImageName,
                job: p.occupation ?? "Not specified",
                height: Int(p.height ?? "0") ?? 0,
                university: "",
                drinking: "",
                smoking: "",
                oneLineIntro: defaultStatus,
                selfIntro: "Hi there!",
                imageNames: [fetchedImageName]
            )
            users.append(newUser)
        }
        return users
    }
    
    // Extracted ProfileResponse since we reuse it now
    struct ProfileResponse: Decodable {
        let id: String
        let nickname: String?
        let birth_date: String?
        let occupation: String?
        let height: String?
    }

    /// Fetches users who have liked the active user
    func fetchPendingLikes() async throws -> [User] {
        let client = AuthManager.shared.client
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        let profiles: [ProfileResponse] = try await client.rpc("get_pending_likes")
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
        return await convertProfilesToUsers(profiles, defaultStatus: "Liked you!")
    }
    
    /// Fetches established friends
    func fetchFriends() async throws -> [User] {
        let client = AuthManager.shared.client
        let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
        let profiles: [ProfileResponse] = try await client.rpc("get_friends")
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
        return await convertProfilesToUsers(profiles, defaultStatus: "Your Friend")
    }
}
