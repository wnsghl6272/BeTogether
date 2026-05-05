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
    
    // Persona suggestion states
    @State private var personaSuggestions: [PersonaSuggestion] = []
    @State private var isLoadingPersonas: Bool = true
    @State private var typingTexts: [String] = ["", "", ""]
    @State private var typingDone: [Bool] = [false, false, false]
    
    // Store Integration
    @StateObject private var store = StoreManager.shared
    @State private var checkInMessage = ""
    @State private var alreadyCheckedIn = false
    
    struct PersonaSuggestion: Identifiable {
        let id = UUID()
        let emoji: String
        let label: String
        let fullQuery: String
        let tagline: String
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // ── Daily Attendance Banner ──
            Button(action: {
                if !alreadyCheckedIn {
                    Task {
                        let result = await store.checkDailyAttendance()
                        checkInMessage = result.message
                        alreadyCheckedIn = true
                    }
                }
            }) {
                HStack {
                    Image(systemName: alreadyCheckedIn ? "checkmark.circle.fill" : "gift.fill")
                        .foregroundColor(alreadyCheckedIn ? .green : .yellow)
                    Text(alreadyCheckedIn ? "Checked In Today" : "Tap here for Daily Check-in!")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(alreadyCheckedIn ? Color.black.opacity(0.8) : Color.btTeal)
                .cornerRadius(12)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            
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
                            
                            // ── AI Persona Suggestions ──
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.caption)
                                        .foregroundColor(.btTeal)
                                    Text("Tailored for you")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 4)
                                
                                if isLoadingPersonas {
                                    // Shimmer loading placeholders
                                    HStack(spacing: 8) {
                                        ForEach(0..<3, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(Color(.systemGray5).opacity(0.6))
                                                .frame(width: 140, height: 80)
                                                .shimmering()
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(Array(personaSuggestions.enumerated()), id: \.element.id) { index, persona in
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        query = persona.fullQuery
                                                    }
                                                }) {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack(spacing: 4) {
                                                            Text(persona.emoji)
                                                                .font(.system(size: 16))
                                                            Text(persona.label)
                                                                .font(.caption2)
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.btTeal)
                                                        }
                                                        
                                                        Text(typingDone[safe: index] == true ? persona.tagline : (typingTexts[safe: index] ?? ""))
                                                            .font(.caption)
                                                            .foregroundColor(.primary.opacity(0.8))
                                                            .lineLimit(2)
                                                            .multilineTextAlignment(.leading)
                                                            .frame(minHeight: 32, alignment: .topLeading)
                                                    }
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 10)
                                                    .frame(width: 160, alignment: .leading)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .fill(.ultraThinMaterial)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(
                                                                LinearGradient(
                                                                    colors: [Color.btTeal.opacity(0.4), Color.purple.opacity(0.2), Color.btTeal.opacity(0.15)],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                                lineWidth: 1.2
                                                            )
                                                    )
                                                    .shadow(color: Color.btTeal.opacity(0.08), radius: 6, x: 0, y: 3)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
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
                                            
                                            // Coin Indicator
                                            HStack(spacing: 2) {
                                                Image(systemName: "bitcoinsign.circle.fill")
                                                Text("2")
                                            }
                                            .font(.caption2.bold())
                                            .foregroundColor(.yellow)
                                            .padding(.leading, 4)
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
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            .onAppear {
                Task {
                    await loadPersonaSuggestions()
                    checkIfAlreadyCheckedIn()
                }
            }
            .onChange(of: store.economy) { _ in
                checkIfAlreadyCheckedIn()
            }
            .fullScreenCover(isPresented: $showMatchesModal) {
                AiMatchesModalView(
                    matchedUsers: $matchedUsers,
                    matchReasonsArray: $matchReasonsArray,
                    showMatchesModal: $showMatchesModal,
                    matchedByPreference: matchedByPreference,
                    onAction: { actionStr, user in
                        handleCardAction(action: actionStr, matchedUser: user)
                    }
                )
            }
            .alert("Not Enough Coins", isPresented: $showCoinAlert) {
                Button("Got It", role: .cancel) {}
            } message: {
                Text("AI Matchmaking costs 2 Coins. Tap the coin icon on the top right to get more!")
            }
    }
    
    private func checkIfAlreadyCheckedIn() {
        if let lastDate = store.economy?.lastAttendanceDate,
           Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            alreadyCheckedIn = true
            checkInMessage = "You already checked in today!"
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
    
    @State private var showCoinAlert = false

    private func fetchAiRecommendation() async {
        let success = await StoreManager.shared.spendCoins(amount: 2)
        if !success {
            await MainActor.run {
                showCoinAlert = true
            }
            return
        }
        
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
    
    // MARK: - Persona Suggestions
    
    private func loadPersonaSuggestions() async {
        guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
              let userId = AuthManager.shared.currentUserId else {
            await MainActor.run { isLoadingPersonas = false }
            return
        }
        
        do {
            let client = AuthManager.shared.client
            
            // Fetch profile data
            struct ProfileResult: Decodable {
                let occupation: String?
                let gender: String?
                let one_line_intro: String?
            }
            let profiles: [ProfileResult] = (try? await client.from("profiles")
                .select("occupation, gender, one_line_intro")
                .eq("id", value: userId)
                .execute()
                .value) ?? []
            
            // Fetch user traits
            struct TraitResult: Decodable {
                let mbti: String?
                let lifestyle: [String: String]?
                let matching_preferences: [String: AnyCodable]?
            }
            let traits: [TraitResult] = (try? await client.from("user_traits")
                .select("mbti, lifestyle, matching_preferences")
                .eq("user_id", value: userId)
                .execute()
                .value) ?? []
            
            let profile = profiles.first
            let trait = traits.first
            
            let suggestions = generatePersonaSuggestions(
                mbti: trait?.mbti,
                lifestyle: trait?.lifestyle,
                occupation: profile?.occupation,
                gender: profile?.gender,
                preferences: trait?.matching_preferences
            )
            
            await MainActor.run {
                self.personaSuggestions = suggestions
                self.isLoadingPersonas = false
                self.typingTexts = Array(repeating: "", count: suggestions.count)
                self.typingDone = Array(repeating: false, count: suggestions.count)
            }
            
            // Start typewriter animation
            for i in 0..<suggestions.count {
                await startTypingAnimation(index: i, text: suggestions[i].tagline)
            }
        }
    }
    
    private func generatePersonaSuggestions(
        mbti: String?,
        lifestyle: [String: String]?,
        occupation: String?,
        gender: String?,
        preferences: [String: AnyCodable]?
    ) -> [PersonaSuggestion] {
        var suggestions: [PersonaSuggestion] = []
        
        // MBTI best match partner type map
        let mbtiIdealPartners: [String: (type: String, desc: String)] = [
            "INTJ": ("ENFP", "creative and spontaneous"),
            "INTP": ("ENTJ", "decisive and driven"),
            "ENTJ": ("INFP", "empathetic and imaginative"),
            "ENTP": ("INFJ", "insightful and warm"),
            "INFJ": ("ENTP", "witty and adventurous"),
            "INFP": ("ENTJ", "confident and structured"),
            "ENFJ": ("ISTP", "calm and practical"),
            "ENFP": ("INTJ", "strategic and deep"),
            "ISTJ": ("ESFP", "fun-loving and spontaneous"),
            "ISFJ": ("ESTP", "energetic and bold"),
            "ESTJ": ("ISFP", "gentle and artistic"),
            "ESFJ": ("ISTP", "independent and cool"),
            "ISTP": ("ESFJ", "warm and caring"),
            "ISFP": ("ESTJ", "reliable and organized"),
            "ESTP": ("ISFJ", "thoughtful and loyal"),
            "ESFP": ("ISTJ", "steady and dependable")
        ]
        
        // ── Suggestion 1: MBTI-based ideal partner ──
        let mbtiType = mbti ?? "ENFP"
        let idealPartner = mbtiIdealPartners[mbtiType] ?? ("ENFP", "creative and spontaneous")
        
        let mbtiTemplates = [
            "How about meeting a \(idealPartner.desc) \(idealPartner.type)?",
            "An \(idealPartner.type) could be your perfect balance ✨",
            "Your \(mbtiType) pairs best with \(idealPartner.type)!",
            "Today, try a \(idealPartner.desc) partner?"
        ]
        
        suggestions.append(PersonaSuggestion(
            emoji: "🧠",
            label: "Soul Match",
            fullQuery: "I'm \(mbtiType), find me someone \(idealPartner.desc) like \(idealPartner.type)",
            tagline: mbtiTemplates.randomElement()!
        ))
        
        // ── Suggestion 2: Lifestyle-based ──
        let drink = lifestyle?["Drinking"] ?? lifestyle?["drinking"] ?? "Socially"
        let smoke = lifestyle?["Smoking"] ?? lifestyle?["smoking"] ?? "Non-smoker"
        let workout = lifestyle?["Workout"] ?? lifestyle?["workout"]
        let loveLang = lifestyle?["Love Language"] ?? lifestyle?["love_language"]
        
        var lifestyleDesc: [String] = []
        if smoke.lowercased().contains("non") || smoke.lowercased().contains("never") {
            lifestyleDesc.append("non-smoker")
        }
        if drink.lowercased().contains("social") {
            lifestyleDesc.append("social drinker")
        }
        if let w = workout, w.lowercased().contains("daily") {
            lifestyleDesc.append("fitness lover")
        }
        if let lang = loveLang {
            lifestyleDesc.append("who values \(lang)")
        }
        
        let lifestyleQuery = lifestyleDesc.isEmpty ?
            "Someone who shares my lifestyle" :
            "Find me a \(lifestyleDesc.prefix(3).joined(separator: ", "))"
        
        let lifestyleTemplates = [
            "Someone who vibes with your lifestyle 🎯",
            "Match your daily rhythm perfectly",
            "Find your lifestyle twin today",
            "Same energy, same vibe ✨"
        ]
        
        suggestions.append(PersonaSuggestion(
            emoji: "🌿",
            label: "Lifestyle Match",
            fullQuery: lifestyleQuery,
            tagline: lifestyleTemplates.randomElement()!
        ))
        
        // ── Suggestion 3: Creative / Occupation-based ──
        let occ = occupation ?? "professional"
        let prefGender = preferences?["preferred_gender"]?.value as? String
        
        let creativeTemplates = [
            "Discover someone who inspires you",
            "A creative soul to spark something new",
            "Meet your unexpected perfect match 💫",
            "Step out of your comfort zone today"
        ]
        
        let genderHint = prefGender != nil && prefGender != "Any" ? " (\(prefGender!))" : ""
        
        suggestions.append(PersonaSuggestion(
            emoji: "✨",
            label: "Surprise Me",
            fullQuery: "I'm a \(occ), surprise me with someone special\(genderHint)",
            tagline: creativeTemplates.randomElement()!
        ))
        
        return suggestions
    }
    
    private func startTypingAnimation(index: Int, text: String) async {
        let chars = Array(text)
        for i in 0..<chars.count {
            try? await Task.sleep(nanoseconds: 30_000_000) // 30ms per char
            await MainActor.run {
                if index < typingTexts.count {
                    typingTexts[index] = String(chars[0...i])
                }
            }
        }
        await MainActor.run {
            if index < typingDone.count {
                typingDone[index] = true
            }
        }
    }

}

// MARK: - Safe Array Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.white.opacity(0.4),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - AI Matches Modal View
struct AiMatchesModalView: View {
    @Binding var matchedUsers: [User]
    @Binding var matchReasonsArray: [[String]]
    @Binding var showMatchesModal: Bool
    let matchedByPreference: Bool
    let onAction: (String, User) -> Void
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with close button
                    HStack {
                        Text("AI Recommendations (\(matchedUsers.count))")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        Spacer()
                        Button(action: { showMatchesModal = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                    
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
                            onAction(actionStr, firstUser)
                        }
                        .padding(.horizontal, 14)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        .id(firstUser.id) // Ensure transition happens when ID changes
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }
}
