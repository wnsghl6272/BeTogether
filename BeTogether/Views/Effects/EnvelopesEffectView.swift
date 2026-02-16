import SwiftUI

struct EnvelopesEffectView<Content: View>: View {
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
            
            // Envelopes Overlay
            if !isRevealed {
                envelopesOverlay
            }
        }
    }
    
    var envelopesOverlay: some View {
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
                    Spacer()
                    Text("Tap the Envelopes!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 50)
                        .shadow(radius: 5)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            // 4 Envelopes arranged in a 2x2 grid
            VStack(spacing: 30) {
                HStack(spacing: 40) {
                    envelopeItem(index: 0, color: .orange)
                    envelopeItem(index: 1, color: .pink)
                }
                HStack(spacing: 40) {
                    envelopeItem(index: 2, color: .blue)
                    envelopeItem(index: 3, color: .green)
                }
            }
        }
        .cornerRadius(20)
    }
    
    func envelopeItem(index: Int, color: Color) -> some View {
        let isOpened = poppedIndices.contains(index)
        
        return Button(action: {
            handleEnvelopeTap(index: index)
        }) {
            ZStack {
                if isOpened {
                    // Opened Envelope with Text
                    VStack(spacing: 5) {
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 40))
                            .foregroundColor(color)
                            .shadow(color: color.opacity(0.8), radius: 10, x: 0, y: 0)
                        
                        Text(getEnvelopeText(for: index))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Closed Envelope
                    ZStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 60))
                            .foregroundColor(color)
                            .shadow(radius: 5)
                        
                        Image(systemName: "heart.fill") // Seal
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .offset(y: 5)
                    }
                    .scaleEffect(1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
                }
            }
            .frame(width: 120, height: 100)
        }
        .disabled(isOpened)
    }
    
    func handleEnvelopeTap(index: Int) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
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
    
    func getEnvelopeText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
