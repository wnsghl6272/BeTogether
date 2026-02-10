import SwiftUI

struct PersonalityQAView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    @State private var currentQuestionIndex = 0
    @State private var progress: Double = 0.0
    
    struct QAQuestion {
        let category: String
        let icon: String // Emoji
        let question: String
        let options: [String]
    }
    
    let questions: [QAQuestion] = [
        QAQuestion(
            category: "Skinship",
            icon: "💕",
            question: "How do you feel about public displays of affection?",
            options: ["Love it! Everywhere provided.", "Fine with holding hands.", "Prefer to keep it private."]
        ),
        QAQuestion(
            category: "Drinking",
            icon: "🍺",
            question: "What is your drinking style?",
            options: ["Enjoy the atmosphere.", "Drink until I drop!", "Prefer non-alcoholic fun."]
        ),
        QAQuestion(
            category: "Dating",
            icon: "💑",
            question: "How often do you prefer to contact your partner?",
            options: ["Every hour!", "Morning & Night.", "Just for making plans.", "When I have time."]
        ),
        QAQuestion(
            category: "Spending",
            icon: "💸",
            question: "What's your stance on dating expenses?",
            options: ["I'll pay for everything.", "Let's go 50/50.", "Take turns paying.", "Whoever asks pays."]
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
            userSession.advanceToNextStep()
        }
    }
}

#Preview {
    PersonalityQAView()
        .environmentObject(UserSessionViewModel())
}
