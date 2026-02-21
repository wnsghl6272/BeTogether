import SwiftUI

struct SparkleDustEffectView<Content: View>: View {
    let user: User
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    @State private var positions: [CGPoint] = []
    
    init(user: User, isRevealed: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.user = user
        self._isRevealed = isRevealed
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Main Content with Blur
            content
                .blur(radius: isRevealed ? 0 : CGFloat(max(0, 20 - (poppedIndices.count * 5))))
                .animation(.easeInOut(duration: 1.0), value: poppedIndices.count)
                .animation(.easeInOut(duration: 2.5), value: isRevealed)
            
            // Sparkle Dust Overlay
            if !isRevealed {
                sparkleDustOverlay
            }
        }
        .onAppear {
            if positions.isEmpty {
                generateRandomSparklePositions()
            }
        }
    }
    
    var sparkleDustOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Fog
                ForEach(0..<4) { index in
                    if poppedIndices.count <= index {
                        Color.white.opacity(0.15)
                            .allowsHitTesting(false)
                            .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
                    }
                }
                
                // Tap Hint
                if poppedIndices.isEmpty {
                    VStack {
                        Text("Tap the Magic Dust!")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 50)
                            .shadow(radius: 5)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                
                // Sparkle Dust Particles
                ForEach(0..<4) { index in
                    if !poppedIndices.contains(index) && index < positions.count {
                        Button(action: {
                            handleSparkleTap(index: index)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(gradient: Gradient(colors: [.white, .yellow.opacity(0.0)]), center: .center, startRadius: 2, endRadius: 20))
                                    .frame(width: 60, height: 60)
                                    .blur(radius: 5)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 30))
                                    .foregroundColor(.yellow)
                                    .shadow(color: .orange, radius: 5)
                                    .scaleEffect(1.2)
                                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
                            }
                        }
                        .position(positions[index])
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Revealed Info Text (appears briefly then fades or stays? Let's make it appear in place or center)
                // Design decision: Show text in center like magnify or pop reveal
                if let lastIndex = poppedIndices.max(), poppedIndices.count < 5 {
                     // Show the latest revealed info in a nice way
                     VStack {
                         Spacer()
                         Text(getSparkleText(for: lastIndex))
                             .font(.largeTitle)
                             .fontWeight(.heavy)
                             .foregroundColor(.white)
                             .shadow(color: .purple, radius: 10)
                             .padding()
                             .background(Capsule().fill(Color.black.opacity(0.3)).blur(radius: 5))
                             .transition(.move(edge: .bottom).combined(with: .opacity))
                             .id("sparkleText-\(lastIndex)")
                         Spacer().frame(height: 100)
                     }
                     .allowsHitTesting(false)
                }
            }
        }
        .cornerRadius(20)
    }
    
    func generateRandomSparklePositions() {
        var newPositions: [CGPoint] = []
        for _ in 0..<4 {
            let x = CGFloat.random(in: 60...280) // approx width range
            let y = CGFloat.random(in: 100...450) // approx he
            newPositions.append(CGPoint(x: x, y: y))
        }
        positions = newPositions
    }
    
    func handleSparkleTap(index: Int) {
        SoundManager.shared.playSound(named: "SparkleDustEffectView")
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            _ = poppedIndices.insert(index)
        }
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if poppedIndices.count == 4 {
            withAnimation(.easeInOut(duration: 2.0).delay(1.0)) {
                isRevealed = true
            }
        }
    }
    
    func getSparkleText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
