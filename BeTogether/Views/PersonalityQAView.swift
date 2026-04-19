import SwiftUI

struct PersonalityQAView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    @State private var currentQuestionIndex = 0
    @State private var progress: Double = 0.0
    
    struct QAQuestion {
        let category: String
        let icon: String // Emoji
        let question: String
        let options: [String]
    }
    
    let questions: [QAQuestion] = [
        // 1. Skinship
        QAQuestion(
            category: "Physical affection",
            icon: "💕",
            question: "How fast do you progress with physical affection?",
            options: ["Slowly, after building trust", "Naturally, as we feel it", "Quickly, if I like them", "Ideally on the first date"]
        ),
        QAQuestion(
            category: "Physical affection",
            icon: "💋",
            question: "What are your thoughts on PDA?",
            options: ["I love showing affection anywhere", "Holding hands is fine", "Only in private places", "I'm shy about public affection"]
        ),
        QAQuestion(
            category: "Physical affection",
            icon: "🤝",
            question: "How important is physical touch to you?",
            options: ["Essential for connection", "Important but not everything", "Nice to have", "Not a priority"]
        ),
        

        QAQuestion(
            category: "Dating style",
            icon: "📅",
            question: "Are you a planner or impulsive?",
            options: ["Detailed planner (J)", "Rough plan is enough", "Go with the flow (P)", "Completely spontaneous"]
        ),
        QAQuestion(
            category: "Dating style",
            icon: "📱",
            question: "How important is contact frequency?",
            options: ["All day, every detail", "Morning, Lunch, Night", "Once a day is enough", "Only for setting dates"]
        ),
        QAQuestion(
            category: "Dating style",
            icon: "🏠",
            question: "Home date vs Outdoor date?",
            options: ["Cozy home date with Netflix", "Exploring cafes/restaurants", "Active outdoor activities", "Mix of both is best"]
        ),
        
        // 4. Spending Habits
        QAQuestion(
            category: "Spending habits",
            icon: "💸",
            question: "How do you split date costs?",
            options: ["I prefer to pay", "Let's split 50/50", "Take turns paying", "Whoever suggests pays"]
        ),
        QAQuestion(
            category: "Spending habits",
            icon: "💰",
            question: "Are you a saver or a spender?",
            options: ["Strict saver for future", "Balance saving/spending", "Enjoy the present moment", "Love treating myself"]
        ),
        QAQuestion(
            category: "Spending habits",
            icon: "👜",
            question: "Do you care about luxury brands?",
            options: ["Very important", "Nice to have quality items", "Not interested at all", "Prefer unique/vintage"]
        )
    ]
    
    @State private var answers: [[String: String]] = []
    @State private var isSaving: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Progress Bar
                ProgressView(value: Double(currentQuestionIndex + 1), total: Double(questions.count))
                    .accentColor(.purple)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                Spacer()
                
                // Category Badge
                HStack(spacing: 5) {
                    Text(questions[currentQuestionIndex].icon)
                    Text(questions[currentQuestionIndex].category)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.btTeal.opacity(0.1))
                .foregroundColor(.btTeal)
                .cornerRadius(20)
                .transition(.opacity)
                
                // Question
                Text(questions[currentQuestionIndex].question)
                    .font(.btHeader) // Using our custom font extension
                    .foregroundColor(.btTeal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                    .id("q_\(currentQuestionIndex)") // Force redraw for transition
                
                if isSaving {
                    ProgressView()
                        .padding()
                }
                
                // Options
                VStack(spacing: 15) {
                    ForEach(questions[currentQuestionIndex].options.indices, id: \.self) { index in
                        Button(action: {
                            advanceQuestion(with: questions[currentQuestionIndex].options[index])
                        }) {
                            Text(questions[currentQuestionIndex].options[index])
                                .font(.btButton)
                                .foregroundColor(.btTeal)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.btTeal, lineWidth: 2)
                                )
                        }
                        .disabled(isSaving)
                    }
                }
                .padding(.horizontal, 40)
                .id("opt_\(currentQuestionIndex)")
                
                Spacer()
            }
        }
    }
    
    func advanceQuestion(with answer: String) {
        answers.append([
            "category": questions[currentQuestionIndex].category,
            "question": questions[currentQuestionIndex].question,
            "answer": answer
        ])
        
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            // Finish
            isSaving = true
            Task {
                do {
                    try await AuthManager.shared.updateUserTraits(data: ["answers": answers])
                    try await AuthManager.shared.updateProfile(data: ["onboarding_step": "lifestyleOptions"])
                    await MainActor.run {
                        isSaving = false
                        router.navigate(to: .lifestyleOptions)
                    }
                } catch {
                    print("Error saving QA answers: \(error)")
                    await MainActor.run {
                        isSaving = false
                        router.navigate(to: .lifestyleOptions)
                    }
                }
            }
        }
    }
}

#Preview {
    PersonalityQAView()
        .environmentObject(UserSessionViewModel())
}

struct LifestyleOptionsView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Using a simple dictionary to hold selected lifestyle options
    @State private var selections: [String: String] = [:]
    @State private var isSaving: Bool = false
    
    let lifestyleCategories = [
        ("Zodiac Sign", ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]),
        ("Education", ["High School", "In College", "Undergraduate", "Postgraduate"]),
        ("Family Plans", ["Want children", "Don't want children", "Not sure yet"]),
        ("Communication Style", ["Constant texter", "Video chatter", "Bad texter", "Call me"]),
        ("Love Language", ["Words of Affirmation", "Quality Time", "Receiving Gifts", "Acts of Service", "Physical Touch"]),
        ("Pets", ["Dog lover", "Cat lover", "All pets", "No pets"]),
        ("Drinking", ["Non-drinker", "Socially", "Reviewer"]),
        ("Smoking", ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]),
        ("Workout", ["Everyday", "Often", "Sometimes", "Never"])
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Lifestyle & Preferences")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Text("Let others know a bit more about you.")
                .font(.btBody)
                .foregroundColor(.btDarkGrey)
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    ForEach(lifestyleCategories, id: \.0) { category in
                        VStack(alignment: .leading, spacing: 15) {
                            Text(category.0)
                                .font(.btSubheader)
                                .foregroundColor(.btDarkGrey)
                            
                            // Wrapping items 
                            FlowLayout(spacing: 10) {
                                ForEach(category.1, id: \.self) { option in
                                    let isSelected = selections[category.0] == option
                                    Text(option)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.btTeal : Color.gray.opacity(0.1))
                                        .foregroundColor(isSelected ? .white : .btDarkGrey)
                                        .cornerRadius(20)
                                        .onTapGesture {
                                            if isSelected {
                                                selections.removeValue(forKey: category.0)
                                            } else {
                                                selections[category.0] = option
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            
            VStack {
                if isSaving {
                    ProgressView()
                        .padding(.bottom, 10)
                }
                
                BTButton(title: "Save & Continue", action: {
                    saveLifestyleData()
                }, isDisabled: isSaving)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    private func saveLifestyleData() {
        isSaving = true
        userSession.lifestyle = selections
        
        Task {
            do {
                // Update lifestyle via AuthManager
                // Since lifestyle is stored as a JSONB column in user_traits
                try await AuthManager.shared.updateUserTraits(data: ["lifestyle": selections])
                try await AuthManager.shared.updateProfile(data: ["onboarding_step": "matchingPreference"])
                
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .matchingPreference)
                }
            } catch {
                print("Failed to save lifestyle data: \(error)")
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .matchingPreference)
                }
            }
        }
    }
}

// FlowLayout helper for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight + spacing
        }
        return CGSize(width: proposal.width ?? 0, height: max(0, height - spacing))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var width: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if width + size.width > maxWidth, !rows[0].isEmpty {
                rows.append([view])
                width = size.width + spacing
            } else {
                rows[rows.count - 1].append(view)
                width += size.width + spacing
            }
        }
        return rows
    }
}
