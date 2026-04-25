import SwiftUI
import Supabase

struct AiChatInterfaceView: View {
    @State private var query: String = ""
    @State private var isPredicting: Bool = false
    @State private var matchedUsers: [User] = []
    @State private var matchReasonsArray: [[String]] = []
    @State private var showMatchesModal: Bool = false
    @State private var matchedByPreference: Bool = true
    @State private var showMBTIModal: Bool = false
    
    let sampleMBTITags = ["INTJ", "INFP", "ENFP", "ENTJ", "ISFJ", "ESFP", "INFJ", "ESTJ", "ISFP", "INTP", "ESTP", "ISTP", "ESFJ", "ENFJ", "ENTP", "ISTJ"]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    
                    // ── MBTI Compatibility Guide Banner ──
                    Button(action: {
                        showMBTIModal = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MBTI Compatibility Guide")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.black)
                                Text("Tap to find your perfect match type")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.pink.opacity(0.15), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 14)
                    .sheet(isPresented: $showMBTIModal) {
                        // Mock MBTI Info View
                        NavigationView {
                            ScrollView {
                                VStack(spacing: 20) {
                                    Text("Coming Soon: Detailed compatibility guides for each MBTI type!")
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                            }
                            .navigationTitle("MBTI Guide")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }

                    VStack(spacing: 0) {
                        // ── Header ──
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.btTeal.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.btTeal)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Matchmaker")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Tell us who you want to meet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        Divider().opacity(0.4)
                        
                        // ── Text Input Area ──
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe your ideal partner freely")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(minHeight: 90)
                                
                                if query.isEmpty {
                                    Text("e.g. I want to meet a 23-28 y/o non-smoker who loves working out...")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.systemGray3))
                                        .padding(.horizontal, 14)
                                        .padding(.top, 12)
                                }
                                
                                TextEditor(text: $query)
                                    .font(.subheadline)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 90)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .disabled(isPredicting)
                            }
                            .padding(.horizontal, 16)
                            
                            // ── MBTI Quick Tags ──
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Looking for specific MBTI?")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(sampleMBTITags, id: \.self) { mbti in
                                            Button(action: {
                                                if query.isEmpty {
                                                    query = mbti
                                                } else {
                                                    query += ", \(mbti)"
                                                }
                                            }) {
                                                Text(mbti)
                                                    .font(.caption)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(query.contains(mbti) ? Color.btTeal : Color.btTeal.opacity(0.1))
                                                    .foregroundColor(query.contains(mbti) ? .white : .btTeal)
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.bottom, 8)
                            
                            // ── Send Button ──
                            HStack {
                                Spacer()
                                Button(action: {
                                    Task { await fetchAiRecommendation() }
                                }) {
                                    HStack(spacing: 8) {
                                        if isPredicting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.85)
                                            Text("AI is analyzing...")
                                                .font(.subheadline.bold())
                                        } else {
                                            Image(systemName: "paperplane.fill")
                                            Text("Start AI Matching")
                                                .font(.subheadline.bold())
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(query.isEmpty || isPredicting ? Color.gray.opacity(0.5) : Color.btTeal)
                                    .clipShape(Capsule())
                                    .shadow(color: Color.btTeal.opacity(query.isEmpty || isPredicting ? 0.001 : 0.35), radius: 8, x: 0, y: 4)
                                }
                                .disabled(query.isEmpty || isPredicting)
                                .animation(.easeInOut(duration: 0.2), value: query.isEmpty)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }
                        
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 14)
                    
                    // ── Inline Matches Result ──
                    if showMatchesModal && !matchedUsers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI Recommendations (\(matchedUsers.count))")
                                    .font(.headline)
                                    .padding(.horizontal, 16)
                                Spacer()
                            }
                            
                            if matchedByPreference {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.green)
                                    Text("We found perfect matches based on your preferences! ✨")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.08))
                                .cornerRadius(8)
                                .padding(.horizontal, 14)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("It seems your perfect match is away, so we slightly broadened your criteria to find someone you might click with!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.08))
                                .cornerRadius(8)
                                .padding(.horizontal, 14)
                            }
                            
                            if let firstUser = matchedUsers.first, let firstReason = matchReasonsArray.first {
                                PhotoCardView(user: firstUser, effect: .aiReveal(reasons: firstReason)) { actionStr in
                                    handleCardAction(action: actionStr, matchedUser: firstUser)
                                }
                                .padding(.horizontal, 14)
                                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                                .id(firstUser.id) // Ensure transition happens when ID changes
                            }
                        }
                        .id("matchesResult")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showMatchesModal)
                    } else {
                        // ── Placeholder if no results / not searched ──
                        VStack {
                            Spacer()
                            Text("Your destined partner will appear\nhere soon.")
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                                .foregroundColor(Color.gray.opacity(0.6))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: max(200, UIScreen.main.bounds.height - 450))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                                .foregroundColor(Color.gray.opacity(0.3))
                        )
                        .padding(.horizontal, 14)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.vertical, 10)
            }
            .onChange(of: showMatchesModal) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo("matchesResult", anchor: .top)
                        }
                    }
                }
            }
        }
    }
    
    private func handleCardAction(action: String, matchedUser: User) {
        Task {
            do {
                if let targetId = matchedUser.supabaseId {
                    let isMatch = try await InteractionManager.shared.handleUserAction(targetUserId: targetId, actionType: action)
                    if isMatch {
                        // Show match popup for the current user (caller side)
                        let matchInfo = MatchedUserInfo(
                            userId: targetId,
                            name: matchedUser.name,
                            imageUrl: matchedUser.imageName
                        )
                        await MainActor.run {
                            NotificationManager.shared.showMatchPopupForCurrentUser(matchedUser: matchInfo)
                        }
                    }
                }
                
                // Dismiss card smoothly after recording interaction
                await MainActor.run {
                    if let idx = matchedUsers.firstIndex(where: { $0.id == matchedUser.id }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            matchedUsers.remove(at: idx)
                            matchReasonsArray.remove(at: idx)
                            if matchedUsers.isEmpty {
                                showMatchesModal = false
                            }
                        }
                    }
                }
            } catch {
                print("Failed to handle action: \(error)")
            }
        }
    }
    
    private func fetchAiRecommendation() async {
        isPredicting = true
        defer { isPredicting = false }
        
        do {
            // Fetch a fresh, auto-refreshed token
            guard let token = await AuthManager.shared.fetchCurrentAccessToken() else {
                print("AI Error: No session token available")
                return
            }
            
            // Extract user ID from JWT payload (sub claim) — avoids a second async auth call
            guard let currentUserId = Self.extractSubFromJWT(token) else {
                print("AI Error: Could not extract user ID from JWT")
                return
            }
            
            guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/functions/v1/ai-recommendation") else { return }
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
            
            // Print the full response body so we can see the exact error
            let bodyStr = String(data: data, encoding: .utf8) ?? "non-utf8"
            
            guard let http = response as? HTTPURLResponse else { return }
            print("AI Edge Function status: \(http.statusCode), body: \(bodyStr)")
            guard http.statusCode == 200 else { return }
            
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
            // Flexible decoder: answers can be a dict OR an array of dicts
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
            struct Reasons: Decodable {
                let step1: String
                let step2: String
                let step3: String
                let step4: String
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
                
                // Calculate age from birth_date (YYYY-MM...)
                let birthYearString = String((item.candidate.birth_date ?? "").prefix(4))
                let birthYear = Int(birthYearString) ?? 2000
                let currentYear = Calendar.current.component(.year, from: Date())
                let calculatedAge = currentYear - birthYear

                // Use enriched data from the edge function response (no extra DB call needed)
                let userMBTI = item.candidate.mbti ?? "N/A"
                let userLifestyle = item.candidate.lifestyle ?? [:]
                // Convert answers (handles both dict and array formats)
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

            await MainActor.run {
                self.matchedUsers = newMatchedUsers
                self.matchReasonsArray = newMatchReasonsArray
                self.matchedByPreference = result.matchedByPreference ?? true
                self.showMatchesModal = true
            }
            
        } catch {
            print("Failed to fetch recommendation: \(error)")
        }
    }
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

}
