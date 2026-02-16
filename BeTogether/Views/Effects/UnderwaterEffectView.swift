import SwiftUI

struct UnderwaterEffectView<Content: View>: View {
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
            // Main Content with Blur applied locally
            content
                .blur(radius: isRevealed ? 0 : CGFloat(max(0, 20 - (poppedIndices.count * 5))))
                .animation(.easeInOut(duration: 1.0), value: poppedIndices.count)
                .animation(.easeInOut(duration: 2.5), value: isRevealed)
            
            // Overlay
            if !isRevealed {
                underwaterOverlay
            }
        }
    }
    
    var underwaterOverlay: some View {
        ZStack {
            // Background Water Tint
            Color.blue.opacity(0.3)
                .allowsHitTesting(false)
            
            // Background Fog (clears as you pop)
            ForEach(0..<4) { index in
                if poppedIndices.count <= index {
                    Color.blue.opacity(0.1)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
                }
            }
            
            // Tap Hint
            if poppedIndices.isEmpty {
                VStack {
                    Spacer()
                    Text("Pop the Bubbles!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 50)
                        .shadow(radius: 5)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            // 4 Bubbles rising
            GeometryReader { geometry in
                ZStack {
                    underwaterItem(index: 0, position: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7))
                    underwaterItem(index: 1, position: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.6))
                    underwaterItem(index: 2, position: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4))
                    underwaterItem(index: 3, position: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.3))
                }
            }
        }
        .cornerRadius(20)
        .transition(.opacity) // Fade out when revealed
    }
    
    func underwaterItem(index: Int, position: CGPoint) -> some View {
        let isPopped = poppedIndices.contains(index)
        
        return Button(action: {
            handleUnderwaterTap(index: index)
        }) {
            ZStack {
                if isPopped {
                    // Revealed Text
                    VStack(spacing: 5) {
                        Text(getUnderwaterText(for: index))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 5)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.3)))
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Bubble
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.white.opacity(0.4), .blue.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 2))
                        .frame(width: 80, height: 80)
                        .shadow(radius: 5)
                        // Simple floating animation
                        .offset(y: isPopped ? 0 : -10)
                        .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(Double(index) * 0.5), value: UUID())
                }
            }
        }
        .position(position)
        .disabled(isPopped)
    }
    
    func handleUnderwaterTap(index: Int) {
        withAnimation(.easeOut(duration: 0.3)) {
            _ = poppedIndices.insert(index)
        }
        
        // Haptic used to be UIImpactFeedbackGenerator, checking if we can use it here.
        // SwiftUI views can use UIKit classes.
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if poppedIndices.count == 4 {
            withAnimation(.easeInOut(duration: 2.0).delay(1.0)) {
                isRevealed = true
            }
        }
    }
    
    func getUnderwaterText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
