import SwiftUI
import Supabase

struct AiChatInterfaceView: View {
    @State private var query: String = ""
    @State private var isPredicting: Bool = false
    @State private var matchedUser: User?
    @State private var matchReasons: [String] = []
    
    var body: some View {
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
                    Text("어떤 사람을 만나고 싶은지 알려주세요")
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
                Text("원하는 상대방을 자유롭게 설명해주세요")
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
                        Text("예) ISTJ 성격의 운동 좋아하는 23-28세 비흡연자를 만나고 싶어요...")
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
                                Text("AI 분석 중...")
                                    .font(.subheadline.bold())
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("AI 매칭 시작")
                                    .font(.subheadline.bold())
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(query.isEmpty || isPredicting ? Color.gray.opacity(0.5) : Color.btTeal)
                        .clipShape(Capsule())
                        .shadow(color: Color.btTeal.opacity(query.isEmpty || isPredicting ? 0 : 0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(query.isEmpty || isPredicting)
                    .animation(.easeInOut(duration: 0.2), value: query.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            
            // ── Result Card ──
            if let user = matchedUser, !isPredicting {
                Divider().opacity(0.4)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.btTeal)
                        Text("AI가 추천한 매칭 상대")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    
                    PhotoCardView(user: user, effect: .aiReveal(reasons: matchReasons))
                        .transition(.scale.combined(with: .opacity))
                }
                .padding(.bottom, 14)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 14)
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
            
            // DEBUG: print first/last 10 chars of token to verify it's a real JWT
            let preview = String(token.prefix(20)) + "..." + String(token.suffix(10))
            print("AI Debug token preview: \(preview), length: \(token.count)")
            
            guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/functions/v1/ai-recommendation") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])
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
            await MainActor.run {
                self.matchedUser = User.mockUsers.randomElement()
                self.matchReasons = [
                    result.reasons.step1,
                    result.reasons.step2,
                    result.reasons.step3,
                    result.reasons.step4
                ]
            }
            
        } catch {
            print("Failed to fetch recommendation: \(error)")
        }
    }

}
