import SwiftUI
import Supabase

struct AiChatInterfaceView: View {
    @State private var query: String = ""
    @State private var isPredicting: Bool = false
    @State private var matchedUsers: [User] = []
    @State private var matchReasonsArray: [[String]] = []
    @State private var showMatchesModal: Bool = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
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
                                    Text("e.g. I want to meet a 23-28 y/o non-smoker who loves working out and is an ISTJ...")
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
                            
                            TabView {
                                ForEach(matchedUsers.indices, id: \.self) { index in
                                    if index < matchedUsers.count && index < matchReasonsArray.count {
                                        PhotoCardView(user: matchedUsers[index], effect: .aiReveal(reasons: matchReasonsArray[index])) { actionStr in
                                            handleCardAction(action: actionStr, matchedUser: matchedUsers[index])
                                        }
                                        .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .frame(height: 620) // Give fixed space so cards look good
                        }
                        .id("matchesResult")
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showMatchesModal)
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
                        print("It's a MATCH!")
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
            }
            struct CandidateContainer: Decodable {
                let candidate: UserProfileResponse
                let reasons: Reasons
            }
            struct UserProfileResponse: Decodable {
                let id: String
                let nickname: String?
                let birth_date: String?
                let occupation: String?
                let height: String?
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

                let newUser = User(
                    supabaseId: item.candidate.id,
                    name: item.candidate.nickname ?? "Unknown",
                    age: calculatedAge,
                    region: "Online",
                    distance: 0,
                    mbti: "N/A", // Not included in the AI response payload unless joined
                    isOnline: true,
                    isVerified: true,
                    imageName: fetchedImageName,
                    job: item.candidate.occupation ?? "Not specified",
                    height: Int(item.candidate.height ?? "0") ?? 0,
                    university: "",
                    drinking: "",
                    smoking: "",
                    oneLineIntro: "AI Match Selected",
                    selfIntro: "Recommended by AI Matchmaker.",
                    imageNames: allImageNames
                )
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
