import Foundation

/// Service layer for AI recommendation API calls and response parsing.
class AiRecommendationService {
    static let shared = AiRecommendationService()
    private init() {}
    
    // MARK: - Response Types
    
    struct AiResponse: Decodable {
        let candidates: [CandidateContainer]
        let matchedByPreference: Bool?
    }
    
    struct CandidateContainer: Decodable {
        let candidate: UserProfileResponse
        let reasons: Reasons
        let distance: Int?
        let confidenceTier: String?
        let compositeScore: Double?
        let topDimensions: [String]?
    }
    
    struct Reasons: Decodable {
        let step1: String
        let step2: String
        let step3: String
        let step4: String
    }
    
    struct UserProfileResponse: Decodable {
        let id: String
        let full_name: String?
        let nickname: String?
        let birth_date: String?
        let occupation: String?
        let height: String?
        let mbti: String?
        let one_line_intro: String?
        let self_intro: String?
        let lifestyle: [String: String]?
        let answers: FlexibleAnswers?
    }
    
    /// Flexible decoder: answers can be a dict OR an array of dicts
    enum FlexibleAnswers: Decodable {
        case dict([String: String])
        case array([[String: String]])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: String].self) {
                self = .dict(dict)
            } else if let arr = try? container.decode([[String: String]].self) {
                self = .array(arr)
            } else {
                self = .dict([:])
            }
        }
        
        func toDictionary() -> [String: String] {
            switch self {
            case .dict(let d): return d
            case .array(let arr):
                var result: [String: String] = [:]
                for entry in arr {
                    if let q = entry["question"], let a = entry["answer"] {
                        result[q] = a
                    }
                }
                return result
            }
        }
    }
    
    // MARK: - API Call
    
    struct RecommendationResult {
        let users: [User]
        let reasonsArray: [[String]]
        let matchedByPreference: Bool
    }
    
    func fetchRecommendation(query: String) async throws -> RecommendationResult {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken() else {
            throw AiError.noToken
        }
        
        guard let currentUserId = Self.extractSubFromJWT(token) else {
            throw AiError.noUserId
        }
        
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/functions/v1/ai-recommendation") else {
            throw AiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query, "userId": currentUserId])
        request.timeoutInterval = 60
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        
        let bodyStr = String(data: data, encoding: .utf8) ?? "non-utf8"
        
        guard let http = response as? HTTPURLResponse else {
            throw AiError.invalidResponse
        }
        print("AI Edge Function status: \(http.statusCode), body: \(bodyStr)")
        guard http.statusCode == 200 else {
            throw AiError.serverError(http.statusCode)
        }
        
        let result = try JSONDecoder().decode(AiResponse.self, from: data)
        
        var newMatchedUsers: [User] = []
        var newMatchReasonsArray: [[String]] = []
        
        for item in result.candidates {
            var fetchedImageName = "profile_korean_1"
            var allImageNames: [String] = []
            if let userPhotos = try? await AuthManager.shared.fetchUserPhotos(userId: item.candidate.id) {
                if let firstPhoto = userPhotos.first {
                    fetchedImageName = firstPhoto.image_url
                }
                allImageNames = userPhotos.compactMap { $0.image_url }
            }
            
            let birthYearString = String((item.candidate.birth_date ?? "").prefix(4))
            let birthYear = Int(birthYearString) ?? 2000
            let currentYear = Calendar.current.component(.year, from: Date())
            let calculatedAge = currentYear - birthYear
            
            let userMBTI = item.candidate.mbti ?? "N/A"
            let userLifestyle = item.candidate.lifestyle ?? [:]
            let userQA = item.candidate.answers?.toDictionary() ?? [:]
            
            var newUser = User(
                supabaseId: item.candidate.id,
                name: item.candidate.full_name ?? item.candidate.nickname ?? "Unknown",
                age: calculatedAge,
                region: "Online",
                distance: item.distance ?? 0,
                mbti: userMBTI,
                isOnline: true,
                isVerified: true,
                imageName: fetchedImageName,
                job: item.candidate.occupation ?? "Not specified",
                height: Int(item.candidate.height ?? "0") ?? 0,
                university: "",
                drinking: "",
                smoking: "",
                oneLineIntro: item.candidate.one_line_intro ?? "AI Match Selected",
                selfIntro: item.candidate.self_intro ?? "Recommended by AI Matchmaker.",
                imageNames: allImageNames
            )
            newUser.lifestyle = userLifestyle
            newUser.personalQA = userQA.isEmpty ? nil : userQA
            newUser.confidenceTier = item.confidenceTier
            newUser.compositeScore = item.compositeScore
            newUser.topDimensions = item.topDimensions
            
            newMatchedUsers.append(newUser)
            newMatchReasonsArray.append([
                item.reasons.step1,
                item.reasons.step2,
                item.reasons.step3,
                item.reasons.step4
            ])
        }
        
        return RecommendationResult(
            users: newMatchedUsers,
            reasonsArray: newMatchReasonsArray,
            matchedByPreference: result.matchedByPreference ?? true
        )
    }
    
    // MARK: - JWT Helper
    
    /// Decodes the base64url JWT payload and returns the `sub` (user ID) claim.
    static func extractSubFromJWT(_ jwt: String) -> String? {
        let parts = jwt.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        var base64 = parts[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sub = json["sub"] as? String else { return nil }
        return sub
    }
    
    // MARK: - Errors
    
    enum AiError: LocalizedError {
        case noToken, noUserId, invalidURL, invalidResponse, serverError(Int)
        
        var errorDescription: String? {
            switch self {
            case .noToken: return "No session token available"
            case .noUserId: return "Could not extract user ID"
            case .invalidURL: return "Invalid API URL"
            case .invalidResponse: return "Invalid server response"
            case .serverError(let code): return "Server error: \(code)"
            }
        }
    }
}
