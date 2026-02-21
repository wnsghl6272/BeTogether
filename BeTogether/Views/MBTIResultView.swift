import SwiftUI

struct MBTIResultView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Mock Data for MBTI Types and Animals
    let mbtiData: [String: (animal: String, title: String, desc: String, tags: [String])] = [
        "ESFP": ("🐶", "Party Welsh Corgi", "Loves being the center of attention. Generous and energetic.", ["YOLO", "Playful", "High Energy"]),
        "INTJ": ("🦅", "Mastermind Eagle", "Strategic and analytical. Always has a plan.", ["Strategic", "Private", "Ambitious"]),
        "ENFP": ("🐬", "Social Dolphin", "Enthusiastic and creative. Loves connecting with people.", ["Creative", "Social", "Optimistic"]),
        "ISTJ": ("🐢", "Reliable Turtle", "Responsible and organized. Values tradition and order.", ["Reliable", "Organized", "Fact-based"]),
        // Add more as needed... default fallback provided
    ]
    
    var resultData: (animal: String, title: String, desc: String, tags: [String]) {
        return mbtiData[userSession.mbtiResult] ?? ("🦄", "Mystical Unicorn", "A rare and unique personality type.", ["Unique", "Mysterious", "Magical"])
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header Character
                VStack(spacing: 15) {
                    Text(resultData.title)
                        .font(.btHeader)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    Text(userSession.mbtiResult)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.btDarkGrey)
                    
                    
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.3)) // Background aura
                            .frame(width: 250, height: 250)
                            .blur(radius: 20)
                        
                        Triangle()
                            .fill(Color.cyan.opacity(0.3))
                            .frame(width: 300, height: 300)
                            .offset(y: 20)
                        
                        Text(resultData.animal)
                            .font(.system(size: 150))
                            .shadow(radius: 10)
                    }
                    .frame(height: 300)
                    
                    // Tags
                    HStack(spacing: 10) {
                        ForEach(resultData.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.oliveGreen) // Custom color check
                                .cornerRadius(20)
                        }
                    }
                }
                
                // Description Box
                VStack(alignment: .leading, spacing: 15) {
                    Text(resultData.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.btDarkGrey)
                    
                    Text(resultData.desc)
                        .font(.btBody)
                        .foregroundColor(.btDarkGrey)
                        .lineSpacing(6)
                    
                    Text("Free-spirited nature makes exciting energy everywhere. Life without parties is like flat cola!") // Mock extra text
                        .font(.btBody)
                        .foregroundColor(.btDarkGrey)
                        .lineSpacing(6)
                        .padding(.top, 5)
                }
                .padding(25)
                .background(Color.yellow.opacity(0.8)) // Match the user's yellow card
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // Compatibility Grid
                VStack(alignment: .leading, spacing: 15) {
                    Text("\(userSession.mbtiResult) Compatibility")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                        ForEach(["ISFJ", "ISTJ", "ENTJ", "ENTP", "ESFJ", "ESFP", "ESTJ", "ESTP", "INTJ", "INTP", "ISFP", "ISTP", "ENFJ", "ENFP", "INFJ", "INFP"], id: \.self) { type in
                            VStack {
                                Text("🐶") // Placeholder animal
                                    .font(.title2)
                                Text(type)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .background(compatibilityColor(for: type))
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Legend
                    HStack(spacing: 15) {
                        Label("GOOD", systemImage: "square.fill").foregroundColor(.green.opacity(0.3))
                        Label("SOSO", systemImage: "square.fill").foregroundColor(.yellow.opacity(0.3))
                        Label("BAD", systemImage: "square.fill").foregroundColor(.red.opacity(0.3))
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
                
                // Pie Chart (Main vs Side Character)
                VStack(spacing: 20) {
                    Text("Main: \(userSession.mbtiResult), Side: ESFJ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    ZStack {
                        Circle()
                            .trim(from: 0.0, to: 0.88)
                            .stroke(Color.yellow, lineWidth: 50)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .trim(from: 0.88, to: 1.0)
                            .stroke(Color.green, lineWidth: 50)
                            .rotationEffect(.degrees(-90 + 360 * 0.88))
                        
                        Text("88%")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(width: 150, height: 150)
                    .padding(.vertical, 20)
                    
                    HStack(spacing: 20) {
                        Label(userSession.mbtiResult, systemImage: "circle.fill").foregroundColor(.yellow)
                        Label("ESFJ", systemImage: "circle.fill").foregroundColor(.green)
                    }
                }
                .padding(.vertical, 20)
                
                Spacer(minLength: 30)
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // Reset to Test Intro
                        router.navigate(to: .mbtiTestIntro)
                    }) {
                        Text("Test Again")
                            .font(.btButton)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        // Continue to Personality Q&A
                        router.navigate(to: .personalityQAIntro)
                    }) {
                        Text("Continue Registration")
                            .font(.btButton)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple) // User requested Purple
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    // Helper for Mock Compatibility Colors
    func compatibilityColor(for type: String) -> Color {
        // Mock logic
        if type.starts(with: "E") { return Color.green.opacity(0.3) }
        if type.starts(with: "I") { return Color.yellow.opacity(0.3) }
        return Color.red.opacity(0.3)
    }
}

// Helper Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// Extension for one-off color
extension Color {
    static let oliveGreen = Color(red: 0.5, green: 0.5, blue: 0.0)
}

#Preview {
    let vm = UserSessionViewModel()
    vm.mbtiResult = "ESFP"
    return MBTIResultView()
        .environmentObject(vm)
}
