import SwiftUI

struct FogEffectView<Content: View>: View {
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = [] // 0: Name, 1: Age, 2: MBTI, 3: Distance
    
    init(isRevealed: Binding<Bool>, @ViewBuilder content: () -> Content) {
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
            
            // Fog Overlay
            if !isRevealed {
                fogOverlay
            }
        }
    }
    
    var fogOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Approximate positions based on a typical card layout
                // These areas will clear the fog when tapped
                
                // 1. Name Balloon (Top Left)
                fogBalloon(text: "Hello!", index: 0, color: .pink, position: CGPoint(x: 80, y: 150))
                
                // 2. Age Balloon (Top Right)
                fogBalloon(text: "Pop!", index: 1, color: .orange, position: CGPoint(x: geometry.size.width - 80, y: 180))
                
                // 3. MBTI Balloon (Bottom Left)
                fogBalloon(text: "Nice!", index: 2, color: .purple, position: CGPoint(x: 100, y: geometry.size.height - 150))
                
                // 4. Distance Balloon (Bottom Right)
                fogBalloon(text: "Wow!", index: 3, color: .blue, position: CGPoint(x: geometry.size.width - 90, y: geometry.size.height - 200))
                
                // Visual Cloud/Fog Layers
                // We use multiple layers of semi-transparent white with blur
                // to simulate fog. tapping an area exposes it by masking the fog.
                
                if poppedIndices.count < 4 {
                    Color.white.opacity(0.1) // Base haze
                        .allowsHitTesting(false)
                }
                
                // "Tap to Clear" Hint
                if poppedIndices.isEmpty {
                    VStack {
                        Spacer()
                        Text("Tap to Clear Fog")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .shadow(radius: 5)
                            .padding(.bottom, 100)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .background(
            // Dynamic Fog Background
            Color.white.opacity(max(0, 0.4 - Double(poppedIndices.count) * 0.1))
                .blur(radius: 20)
        )
        .cornerRadius(20)
    }
    
    func fogBalloon(text: String, index: Int, color: Color, position: CGPoint) -> some View {
        let isPopped = poppedIndices.contains(index)
        
        return Button(action: {
            handleFogTap(index: index)
        }) {
            ZStack {
                if isPopped {
                    // Popped State: Text floats up and fades
                    Text(text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                        .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                } else {
                    // Balloon State
                    VStack(spacing: 0) {
                        Circle()
                            .fill(
                                LinearGradient(gradient: Gradient(colors: [color.opacity(0.8), color]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 80, height: 90)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 5)
                        
                        // String
                        Path { path in
                            path.move(to: CGPoint(x: 10, y: 0))
                            path.addCurve(to: CGPoint(x: 10, y: 30), control1: CGPoint(x: 0, y: 15), control2: CGPoint(x: 20, y: 15))
                        }
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        .frame(width: 20, height: 30)
                    }
                    .transition(.scale)
                }
            }
        }
        .position(position)
        .disabled(isPopped)
    }
    
    func handleFogTap(index: Int) {
        SoundManager.shared.playSound(named: "FogEffectView")
        
        withAnimation(.easeOut(duration: 1.0)) {
            _ = poppedIndices.insert(index)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if poppedIndices.count == 4 {
            withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                isRevealed = true
            }
        }
    }
}
