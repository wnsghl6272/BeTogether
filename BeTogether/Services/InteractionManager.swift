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
                let full_name: String?
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
            let full_name: String?
            let nickname: String?
            let birth_date: String?
            let occupation: String?
            let height: String?
        }
        
        // In query: in("id", friendIds)
        let profiles: [ProfileResponse] = try await client.from("profiles")
            .select("id, full_name, nickname, birth_date, occupation, height")
            .in("id", values: friendIds)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
            
        let traits: [UserTraitDBResponse] = (try? await client.from("user_traits")
            .select("user_id, mbti")
            .in("user_id", values: friendIds)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value) ?? []
            
        var matchedUsers: [User] = []
        
        for p in profiles {
            let userTrait = traits.first(where: { $0.user_id == p.id })
            
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
                name: p.full_name ?? p.nickname ?? "Unknown",
                age: calculatedAge,
                region: "Matched",
                distance: 0,
                mbti: userTrait?.mbti ?? "N/A",
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
        let targetIds = profiles.map { $0.id }
        
        var traits: [UserTraitDBResponse] = []
        if !targetIds.isEmpty {
            let token = await AuthManager.shared.fetchCurrentAccessToken() ?? ""
            let client = AuthManager.shared.client
            traits = (try? await client.from("user_traits")
                .select("user_id, mbti")
                .in("user_id", values: targetIds)
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute().value) ?? []
        }
        
        for p in profiles {
            let userTrait = traits.first(where: { $0.user_id == p.id })
            
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
                name: p.full_name ?? p.nickname ?? "Unknown",
                age: calculatedAge,
                region: "App User",
                distance: 0,
                mbti: userTrait?.mbti ?? "N/A",
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
        let full_name: String?
        let nickname: String?
        let birth_date: String?
        let occupation: String?
        let height: String?
        let mbti: String?
    }
    
    struct UserTraitDBResponse: Decodable {
        let user_id: String
        let mbti: String?
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
    
    /// Unmatch: delete the match record, related conversation, and interactions
    func unmatch(targetUserId: String) async throws {
        guard let targetUUID = UUID(uuidString: targetUserId) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid target user ID for unmatch"])
        }
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(), !token.isEmpty else {
            throw NSError(domain: "InteractionManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        struct UnmatchParams: Encodable {
            let p_target_user_id: UUID
        }
        
        let client = AuthManager.shared.client
        let _ = try await client.rpc("unmatch_user", params: UnmatchParams(p_target_user_id: targetUUID))
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
    }
    
    /// Remove friend: delete friendship record + remove self from conversation (partner keeps chat)
    func removeFriend(targetUserId: String) async throws {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = await AiChatInterfaceView.extractSubFromJWT(token) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        let client = AuthManager.shared.client
        
        // 1. Delete friendship record (both directions)
        let _ = try? await client.from("friendships")
            .delete()
            .or("and(user1_id.eq.\(currentUserId),user2_id.eq.\(targetUserId)),and(user1_id.eq.\(targetUserId),user2_id.eq.\(currentUserId))")
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
        
        // 2. Remove only the current user from conversation_members (partner keeps the conversation & messages)
        if let convId = await ChatManager.findConversationId(partnerId: targetUserId, type: "friend") {
            let _ = try? await client.from("conversation_members")
                .delete()
                .eq("conversation_id", value: convId)
                .eq("user_id", value: currentUserId)
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute()
        }
    }
    
    // MARK: - Daily Picks Recommendations
    
    struct DailyPickDBRecord: Codable {
        let id: String?
        let user_id: String
        let target_user_id: String
        let picked_date: String
        let is_unlocked: Bool
    }
    
    func fetchDailyPicks() async throws -> [(user: User, isUnlocked: Bool)] {
        let client = AuthManager.shared.client
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = await AiChatInterfaceView.extractSubFromJWT(token) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Ensure UTC for consistency across client sessions
        formatter.timeZone = TimeZone(identifier: "UTC")
        let todayStr = formatter.string(from: Date())
        
        var picks: [DailyPickDBRecord] = try await client.from("daily_picks")
            .select()
            .eq("user_id", value: currentUserId)
            .eq("picked_date", value: todayStr)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
            
        if picks.isEmpty {
            // Fetch 10 random candidates excluding current user
            let allProfiles: [ProfileResponse] = try await client.from("profiles")
                .select("id, full_name, nickname, birth_date, occupation, height")
                .neq("id", value: currentUserId)
                .limit(10)
                .setHeader(name: "Authorization", value: "Bearer \(token)")
                .execute().value
                
            let shuffled = allProfiles.shuffled()
            let selected = Array(shuffled.prefix(2))
            
            for profile in selected {
                let newPick = DailyPickDBRecord(
                    id: UUID().uuidString,
                    user_id: currentUserId,
                    target_user_id: profile.id,
                    picked_date: todayStr,
                    is_unlocked: false
                )
                try await client.from("daily_picks")
                    .insert(newPick)
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                
                picks.append(newPick)
            }
        }
        
        let targetIds = picks.map { $0.target_user_id }
        guard !targetIds.isEmpty else { return [] }
        
        let profiles: [ProfileResponse] = try await client.from("profiles")
            .select("id, full_name, nickname, birth_date, occupation, height")
            .in("id", values: targetIds)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
            
        let traits: [UserTraitDBResponse] = (try? await client.from("user_traits")
            .select("user_id, mbti")
            .in("user_id", values: targetIds)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value) ?? []
            
        var finalUsers: [(user: User, isUnlocked: Bool)] = []
        for pick in picks {
            if let profile = profiles.first(where: { $0.id == pick.target_user_id }) {
                let userTrait = traits.first(where: { $0.user_id == profile.id })
                
                var fetchedImageName = "profile_korean_1"
                if let userPhotos = try? await AuthManager.shared.fetchUserPhotos(userId: profile.id), let firstPhoto = userPhotos.first {
                    fetchedImageName = firstPhoto.image_url
                }
                
                let birthYearString = String((profile.birth_date ?? "").prefix(4))
                let birthYear = Int(birthYearString) ?? 2000
                let currentYear = Calendar.current.component(.year, from: Date())
                let calculatedAge = currentYear - birthYear

                let newUser = User(
                    supabaseId: profile.id,
                    name: profile.full_name ?? profile.nickname ?? "Unknown",
                    age: calculatedAge,
                    region: "App User",
                    distance: Int.random(in: 2...15), // Placeholder for Distance
                    mbti: userTrait?.mbti ?? "ISFP",    // Uses default if not set or found
                    isOnline: false,
                    isVerified: true,
                    imageName: fetchedImageName,
                    job: profile.occupation ?? "Not specified",
                    height: Int(profile.height ?? "0") ?? 0,
                    university: "",
                    drinking: "",
                    smoking: "",
                    oneLineIntro: "Daily Pick",
                    selfIntro: "",
                    imageNames: [fetchedImageName]
                )
                finalUsers.append((user: newUser, isUnlocked: pick.is_unlocked))
            }
        }
        return finalUsers
    }
    
    func unlockDailyPick(targetUserId: String) async throws -> Bool {
        let client = AuthManager.shared.client
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let currentUserId = await AiChatInterfaceView.extractSubFromJWT(token) else {
            throw NSError(domain: "InteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let todayStr = formatter.string(from: Date())
        
        let picks: [DailyPickDBRecord] = try await client.from("daily_picks")
            .select()
            .eq("user_id", value: currentUserId)
            .eq("picked_date", value: todayStr)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute().value
            
        let unlockedCount = picks.filter { $0.is_unlocked }.count
        if unlockedCount >= 1 {
            return false // Free unlock already used
        }
        
        struct UpdatePick: Encodable {
            let is_unlocked: Bool
        }
        
        _ = try await client.from("daily_picks")
            .update(UpdatePick(is_unlocked: true))
            .eq("user_id", value: currentUserId)
            .eq("target_user_id", value: targetUserId)
            .eq("picked_date", value: todayStr)
            .setHeader(name: "Authorization", value: "Bearer \(token)")
            .execute()
            
        return true
    }
}
