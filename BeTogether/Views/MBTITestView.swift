import SwiftUI

struct Question {
    let id: Int
    let text: String
    let optionA: String
    let optionB: String
    let dimension: Dimension // E, N, F, P
    let optionAScore: Int // Usually 1 for one side
    let optionBScore: Int // Usually 1 for other side
}

enum Dimension {
    case Energy // E vs I
    case Information // N vs S
    case Decision // F vs T
    case Lifestyle // P vs J
}

struct MBTITestView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Mock Questions - 12 Total (3 per dimension)
    let questions: [Question] = [
        // N vs S (Information)
        Question(id: 1, text: "When learning something new, you prefer:", optionA: "the principle first, then examples", optionB: "examples first, then the rule/principle", dimension: .Information, optionAScore: 1, optionBScore: -1), // Intuition vs. Sensing
        
        // F vs T (Decision)
        Question(id: 2, text: "You trust feedback more when it’s:", optionA: "considerate and motivating (even if softer)", optionB: "direct and specific (even if it stings)", dimension: .Decision, optionAScore: 1, optionBScore: -1), // Feeling vs. Thinking
        
        // E vs I (Energy)
        Question(id: 3, text: "If you have a free Saturday, you’re more likely to:", optionA: "keep it open and do your own thing", optionB: "make plans with someone", dimension: .Energy, optionAScore: -1, optionBScore: 1), // Introversion vs. Extraversion
        
        // F vs T (Decision)
        Question(id: 4, text: "In disagreements, you feel best when the outcome is:", optionA: "logically correct and fair by principle", optionB: "acceptable to everyone and relationship-safe", dimension: .Decision, optionAScore: -1, optionBScore: 1), // Thinking vs. Feeling
        
        // J vs P (Lifestyle) / N vs S (Information)
        // Opted for N vs S based on "goal+freedom" (N) vs "clear steps" (S)
        Question(id: 5, text: "When reading instructions, you feel safer with:", optionA: "the goal + freedom to choose the method", optionB: "clear steps and exact requirements", dimension: .Information, optionAScore: 1, optionBScore: -1), // Intuition vs. Sensing
        
        // E vs I (Energy)
        Question(id: 6, text: "After a busy day, you feel most “back to normal” after:", optionA: "quiet time alone", optionB: "chatting / being around people", dimension: .Energy, optionAScore: -1, optionBScore: 1), // Introversion vs. Extraversion
        
        // N vs S (Information)
        Question(id: 7, text: "When solving a problem, you’re more drawn to:", optionA: "redesigning the system if there’s a better model", optionB: "improving what already works reliably", dimension: .Information, optionAScore: 1, optionBScore: -1), // Intuition vs. Sensing
        
        // J vs P (Lifestyle)
        Question(id: 8, text: "You feel more comfortable when:", optionA: "options stay open as long as possible", optionB: "decisions are settled and closed", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1), // Perceiving vs. Judging
        
        // E vs I (Energy)
        Question(id: 9, text: "When you’re figuring something out, you tend to:", optionA: "think it through privately, then share", optionB: "talk it through to clarify your thoughts", dimension: .Energy, optionAScore: -1, optionBScore: 1), // Introversion vs. Extraversion
        
        // N vs S (Information)
        Question(id: 10, text: "In conversation, you naturally focus on:", optionA: "what it means + what it could become", optionB: "what happened + practical details", dimension: .Information, optionAScore: 1, optionBScore: -1), // Intuition vs. Sensing
        
        // F vs T (Decision)
        Question(id: 11, text: "When someone is stressed, your default help is:", optionA: "listen + validate + support emotionally first", optionB: "diagnose + offer options to fix it", dimension: .Decision, optionAScore: 1, optionBScore: -1), // Feeling vs. Thinking
        
        // J vs P (Lifestyle)
        Question(id: 12, text: "Deadlines usually make you:", optionA: "start later when urgency kicks in", optionB: "start early so it’s under control", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1), // Perceiving vs. Judging
        
        // F vs T (Decision)
        Question(id: 13, text: "If you must choose one, you prioritise decisions that are:", optionA: "tailored to people’s needs in that situation", optionB: "consistent with objective standards/rules", dimension: .Decision, optionAScore: 1, optionBScore: -1), // Feeling vs. Thinking
        
        // J vs P (Lifestyle)
        Question(id: 14, text: "You prefer your week to be:", optionA: "flexible with room to adapt", optionB: "planned with a clear structure", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1), // Perceiving vs. Judging
        
        // F vs T (Decision)
        Question(id: 15, text: "A teammate delivers results but upsets people often. You lean toward:", optionA: "address it gently to preserve morale and relationships", optionB: "address the impact bluntly and set clear expectations", dimension: .Decision, optionAScore: 1, optionBScore: -1), // Feeling vs. Thinking
        
        // N vs S (Information)
        Question(id: 16, text: "When you summarise a topic, you usually:", optionA: "compress it into a pattern/theme/framework", optionB: "list key facts and concrete points", dimension: .Information, optionAScore: 1, optionBScore: -1) // Intuition vs. Sensing
    ]
    
    @State private var curIndex: Int = 0
    @State private var scores: [Dimension: Int] = [.Energy: 0, .Information: 0, .Decision: 0, .Lifestyle: 0]
    
    var progress: Double {
        return Double(curIndex) / Double(questions.count)
    }
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Progress Bar
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .btTeal))
                    .padding()
                
                Spacer()
                
                // Question Card
                if curIndex < questions.count {
                    VStack(spacing: 30) {
                        Text(questions[curIndex].text)
                            .font(.btHeader)
                            .multilineTextAlignment(.center)
                            .padding()
                            .transition(.opacity)
                        
                        VStack(spacing: 16) {
                            Button(action: { answer(optionA: true) }) {
                                Text(questions[curIndex].optionA)
                                    .font(.btButton)
                                    .foregroundColor(.btTeal)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                            
                            Button(action: { answer(optionA: false) }) {
                                Text(questions[curIndex].optionB)
                                    .font(.btButton)
                                    .foregroundColor(.btTeal)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                    .animation(.easeInOut, value: curIndex)
                }
                
                Spacer()
            }
        }
    }
    
    func answer(optionA: Bool) {
        let q = questions[curIndex]
        let score = optionA ? q.optionAScore : q.optionBScore
        
        scores[q.dimension, default: 0] += score
        
        if curIndex < questions.count - 1 {
            curIndex += 1
        } else {
            calculateResult()
        }
    }
    
    func calculateResult() {
        let e = (scores[.Energy] ?? 0) > 0 ? "E" : "I"
        let n = (scores[.Information] ?? 0) > 0 ? "N" : "S"
        let f = (scores[.Decision] ?? 0) > 0 ? "F" : "T"
        let p = (scores[.Lifestyle] ?? 0) > 0 ? "P" : "J"
        
        let result = "\(e)\(n)\(f)\(p)"
        userSession.completeMBTI(with: result)
        router.navigate(to: .mbtiResult)
    }
}

#Preview {
    MBTITestView()
        .environmentObject(UserSessionViewModel())
}
