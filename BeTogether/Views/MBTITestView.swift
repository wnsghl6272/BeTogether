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
    
    // Mock Questions - 12 Total (3 per dimension)
    let questions: [Question] = [
        // E vs I
        Question(id: 1, text: "At a party, you usually...", optionA: "Talk to many people", optionB: "Stick to a few friends", dimension: .Energy, optionAScore: 1, optionBScore: -1),
        Question(id: 2, text: "After a long week, you prefer...", optionA: "Going out with friends", optionB: "Staying home alone", dimension: .Energy, optionAScore: 1, optionBScore: -1),
        Question(id: 3, text: "You feel more energetic...", optionA: "With others", optionB: "By yourself", dimension: .Energy, optionAScore: 1, optionBScore: -1),
        
        // N vs S
        Question(id: 4, text: "You focus more on...", optionA: "Possibilities & Future", optionB: "Facts & Reality", dimension: .Information, optionAScore: 1, optionBScore: -1),
        Question(id: 5, text: "You trust...", optionA: "Your gut instinct", optionB: "Concrete evidence", dimension: .Information, optionAScore: 1, optionBScore: -1),
        Question(id: 6, text: "You prefer descriptions that are...", optionA: "Metaphorical", optionB: "Literal", dimension: .Information, optionAScore: 1, optionBScore: -1),
        
        // F vs T
        Question(id: 7, text: "In arguments, you prioritize...", optionA: "People's feelings", optionB: "Logic and truth", dimension: .Decision, optionAScore: 1, optionBScore: -1),
        Question(id: 8, text: "You are more capable of being...", optionA: "Compassionate", optionB: "Objective", dimension: .Decision, optionAScore: 1, optionBScore: -1),
        Question(id: 9, text: "When making decisions, you listen to...", optionA: "Your heart", optionB: "Your brain", dimension: .Decision, optionAScore: 1, optionBScore: -1),
        
        // P vs J
        Question(id: 10, text: "You prefer to...", optionA: "Go with the flow", optionB: "Stick to a plan", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1),
        Question(id: 11, text: "Your workspace is usually...", optionA: "A bit messy", optionB: "Organized", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1),
        Question(id: 12, text: "Deadlines represent...", optionA: "Suggestions", optionB: "Commands", dimension: .Lifestyle, optionAScore: 1, optionBScore: -1)
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
    }
}

#Preview {
    MBTITestView()
        .environmentObject(UserSessionViewModel())
}
