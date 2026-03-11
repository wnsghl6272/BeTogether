import SwiftUI

struct AiRevealEffectView<Content: View>: View {
    let user: User
    let candidateReasons: [String] // 4 reasons
    @Binding var isRevealed: Bool
    @ViewBuilder var content: Content
    
    @State private var revealStep = 0 // 0 to 4
    @State private var showReasons = false
    
    // Blur amounts for each step
    let blurAmounts: [CGFloat] = [40, 25, 15, 8, 0]
    
    var body: some View {
        ZStack {
            // Underneath content (The actual card)
            content
                .blur(radius: isRevealed ? 0 : blurAmounts[revealStep])
                .animation(.easeInOut(duration: 0.8), value: revealStep)
                .animation(.easeInOut(duration: 0.8), value: isRevealed)
            
            if !isRevealed {
                // Frost overlay
                Color.black.opacity(0.3)
                    .background(Material.ultraThin)
                    .opacity(1.0 - (Double(revealStep) * 0.25))
                    .cornerRadius(20)
                    .animation(.easeInOut(duration: 0.8), value: revealStep)
                
                // Content Overlay
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AI Matchmaker")
                            .font(.headline)
                            .foregroundColor(.btTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(12)
                        
                        Text("I found a great match for you!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Show reasons progressively
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(0..<min(revealStep + 1, 4), id: \.self) { index in
                                HStack(alignment: .top) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(index == revealStep ? .btTeal : .white.opacity(0.5))
                                    
                                    Text(candidateReasons.indices.contains(index) ? candidateReasons[index] : "")
                                        .font(.subheadline)
                                        .foregroundColor(index == revealStep ? .white : .white.opacity(0.6))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding()
                                .background(Color.black.opacity(index == revealStep ? 0.6 : 0.3))
                                .cornerRadius(12)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .animation(.spring(), value: revealStep)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        advanceStep()
                    }) {
                        Text(revealStep < 3 ? "Tap to Reveal More" : "See Final Match")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.btTeal)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
    }
    
    private func advanceStep() {
        if revealStep < 3 {
            revealStep += 1
        } else {
            // Final step: fully reveal
            withAnimation {
                revealStep = 4
                isRevealed = true
            }
        }
    }
}
