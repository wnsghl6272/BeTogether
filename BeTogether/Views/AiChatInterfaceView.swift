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
    @State private var showCoinAlert = false
    
    // Persona suggestion states
    @State private var personaSuggestions: [PersonaSuggestion] = []
    @State private var isLoadingPersonas: Bool = true
    @State private var typingTexts: [String] = ["", "", ""]
    @State private var typingDone: [Bool] = [false, false, false]
    
    // Store Integration
    @StateObject private var store = StoreManager.shared
    @State private var checkInMessage = ""
    @State private var alreadyCheckedIn = false
    @State private var showStoreSheet = false
    
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
            attendanceBanner
            
            // ── Join Premium Subscription Banner ──
            premiumBanner
            
            // ── MBTI Compatibility Guide Banner ──
            mbtiBanner

            VStack(spacing: 0) {
                // ── Header ──
                aiMatchmakerHeader
                
                Divider().opacity(0.4)
                
                // ── Text Input Area ──
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe your ideal partner freely")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    queryInputField
                    
                    // ── AI Persona Suggestions ──
                    personaSuggestionsSection
                    
                    // ── Send Button ──
                    sendButton
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
    
    // MARK: - Banner Subviews
    
    private var attendanceBanner: some View {
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
    }
    
    private var premiumBanner: some View {
        Button(action: { showStoreSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Join Premium Subscription")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Unlock exclusive perks & get more coins")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.indigo]), startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
        }
        .padding(.horizontal, 14)
        .sheet(isPresented: $showStoreSheet) {
            StoreView()
        }
    }
    
    private var mbtiBanner: some View {
        Button(action: { showMBTIModal = true }) {
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
    }
    
    // MARK: - AI Matchmaker Subviews
    
    private var aiMatchmakerHeader: some View {
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
    }
    
    private var queryInputField: some View {
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
    }
    
    private var personaSuggestionsSection: some View {
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
    }
    
    private var sendButton: some View {
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
    
    // MARK: - Logic
    
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
        let success = await StoreManager.shared.spendCoins(amount: 2)
        if !success {
            await MainActor.run { showCoinAlert = true }
            return
        }
        
        isPredicting = true
        defer { isPredicting = false }
        
        do {
            let result = try await AiRecommendationService.shared.fetchRecommendation(query: query)
            
            await MainActor.run {
                self.matchedUsers = result.users
                self.matchReasonsArray = result.reasonsArray
                self.matchedByPreference = result.matchedByPreference
                self.showMatchesModal = true
            }
        } catch {
            print("Failed to fetch recommendation: \(error)")
        }
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
            try? await Task.sleep(nanoseconds: 30_000_000)
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
