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
        
        // 2. Drinking Style
        QAQuestion(
            category: "Drinking habits",
            icon: "🍺",
            question: "How often do you drink?",
            options: ["Never / Rarely", "Once or twice a week", "Enjoying often with meals", "Party animal!"]
        ),
        QAQuestion(
            category: "Drinking habits",
            icon: "🥂",
            question: "What's your preferred drinking atmosphere?",
            options: ["Quiet talks at an Izakaya", "Lively places with music", "Energetic Clubs/Parties", "Sensible drinking at home"]
        ),
        QAQuestion(
            category: "Drinking habits",
            icon: "🥴",
            question: "What's your habit when drunk?",
            options: ["I get sleepy/quiet", "I become more talkative", "I call everyone", "I become super energetic"]
        ),
        
        // 3. Dating Style
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
                
                // Options
                VStack(spacing: 15) {
                    ForEach(questions[currentQuestionIndex].options.indices, id: \.self) { index in
                        Button(action: {
                            advanceQuestion()
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
                    }
                }
                .padding(.horizontal, 40)
                .id("opt_\(currentQuestionIndex)")
                
                Spacer()
            }
        }
    }
    
    func advanceQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation {
                currentQuestionIndex += 1
            }
        } else {
            // Finish
            router.navigate(to: .matchingPreference)
        }
    }
}

#Preview {
    PersonalityQAView()
        .environmentObject(UserSessionViewModel())
}
