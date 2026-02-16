import SwiftUI

struct CurtainEffectView<Content: View>: View {
    let user: User
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    
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
            
            // Curtain Overlay
            if !isRevealed {
                curtainOverlay
                    .transition(.move(edge: .top).animation(.easeInOut(duration: 2.5)))
            }
        }
    }
    
    var curtainOverlay: some View {
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
                
                // Curtains (Left and Right)
                HStack(spacing: 0) {
                    // Left Curtain
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.indigo, .purple]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: (geometry.size.width / 2) * curtainWidthFactor)
                        .overlay(
                           Rectangle()
                               .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: 5, y: 0)
                    
                    Spacer(minLength: 0)
                    
                    // Right Curtain
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.purple, .indigo]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: (geometry.size.width / 2) * curtainWidthFactor)
                        .overlay(
                           Rectangle()
                               .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.5), radius: 10, x: -5, y: 0)
                }
                
                // Tap Hint
                if poppedIndices.isEmpty {
                    VStack {
                        Spacer()
                        Text("Tap to Open Curtains")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 50)
                            .shadow(radius: 5)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }
                
                // Info Text appearing in the gap
                if poppedIndices.count > 0 && poppedIndices.count < 5 {
                     VStack {
                         Spacer()
                         Text(getCurtainText(for: poppedIndices.count - 1))
                             .font(.largeTitle)
                             .fontWeight(.heavy)
                             .foregroundColor(.white)
                             .shadow(color: .black, radius: 5)
                             .transition(.scale.combined(with: .opacity))
                             .id("curtainText-\(poppedIndices.count)") // Force transition
                         Spacer()
                     }
                     .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle()) // Make full area tappable
            .onTapGesture {
                handleCurtainTap()
            }
        }
        .cornerRadius(20)
    }
    
    var curtainWidthFactor: CGFloat {
        // 4 steps to open: 0 -> 1.0, 1 -> 0.75, 2 -> 0.5, 3 -> 0.25, 4 -> 0.0
        let count = poppedIndices.count
        if count >= 4 { return 0 }
        return 1.0 - (CGFloat(count) * 0.25)
    }
    
    func handleCurtainTap() {
        let nextIndex = poppedIndices.count
        if nextIndex < 4 {
            withAnimation(.easeInOut(duration: 0.8)) {
                _ = poppedIndices.insert(nextIndex)
            }
            
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            if poppedIndices.count == 4 {
                withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                    isRevealed = true
                }
            }
        }
    }
    
    func getCurtainText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
