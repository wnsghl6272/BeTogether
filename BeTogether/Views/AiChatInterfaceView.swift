import SwiftUI

struct AiChatInterfaceView: View {
    @State private var query: String = ""
    @State private var isPredicting: Bool = false
    @State private var matchedUser: User?
    @State private var matchReasons: [String] = []
    
    // In a real app, this comes from the Session
    let currentUserId = "current-logged-in-user-id"
    
    var body: some View {
        VStack(spacing: 12) {
            // Chat Message Bubble
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Tell me who you want to meet today!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(12)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
            
            // Input Field & Button
            HStack {
                TextField("e.g. INFP, non-smoker, under 30...", text: $query)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isPredicting)
                
                Button(action: {
                    Task {
                        await fetchAiRecommendation()
                    }
                }) {
                    if isPredicting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                    }
                }
                .foregroundColor(.white)
                .padding(10)
                .background(query.isEmpty || isPredicting ? Color.gray : Color.btTeal)
                .clipShape(Circle())
                .disabled(query.isEmpty || isPredicting)
            }
            
            // Result Presentation (The recommended photo card)
            if let user = matchedUser, !isPredicting {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Here is your AI Recommendation!")
                        .font(.headline)
                        .padding(.top, 8)
                        
                    PhotoCardView(user: user, effect: .aiReveal(reasons: matchReasons))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
    
    private func fetchAiRecommendation() async {
        isPredicting = true
        defer { isPredicting = false }
        
        do {
            guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/functions/v1/ai-recommendation") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["query": query, "userId": currentUserId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error from edge function: \(String(data: data, encoding: .utf8) ?? "Unknown")")
                return
            }
            
            // Expected Response format from Edge Function
            struct AiResponse: Codable {
                let candidate: UserProfileResponse
                let reasons: Reasons
            }
            
            struct UserProfileResponse: Codable {
                let id: String
                let nickname: String?
                let birth_date: String?
                let occupation: String?
                let height: String?
                // ... map to User model
            }
            
            struct Reasons: Codable {
                let step1: String
                let step2: String
                let step3: String
                let step4: String
            }
            
            let result = try JSONDecoder().decode(AiResponse.self, from: data)
            
            // For MVP, we will pick a mock user based on the Edge function's result, 
            // since User uses mock images and properties currently.
            // In production, you would map `result.candidate` directly into a `User` struct.
            
            await MainActor.run {
                self.matchedUser = User.mockUsers.randomElement() // use mock user for image temporarily
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
