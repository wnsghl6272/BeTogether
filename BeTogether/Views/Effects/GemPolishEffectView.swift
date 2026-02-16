import SwiftUI

struct GemPolishEffectView<Content: View>: View {
    let user: User
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    @State private var gemScratchAmount: [Double] = [0, 0, 0, 0] // 0.0 to 1.0 needed to reveal
    
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
            
            // Gem Polish Overlay
            if !isRevealed {
                gemPolishOverlay
            }
        }
    }
    
    var gemPolishOverlay: some View {
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
            if poppedIndices.isEmpty && gemScratchAmount.allSatisfy({ $0 == 0 }) {
                VStack {
                    Spacer()
                    Text("Rub the Stones to Polish!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 50)
                        .shadow(radius: 5)
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            
            // 4 Gems arranged in a 2x2 grid (or similar to fog/scratch)
            VStack(spacing: 30) {
                HStack(spacing: 40) {
                    gemStone(index: 0, color: .red)  // Ruby
                    gemStone(index: 1, color: .blue) // Sapphire
                }
                HStack(spacing: 40) {
                    gemStone(index: 2, color: .green) // Emerald
                    gemStone(index: 3, color: .purple) // Amethyst
                }
            }
        }
        .cornerRadius(20)
    }
    
    func gemStone(index: Int, color: Color) -> some View {
        let isPolished = poppedIndices.contains(index)
        // Simulate polish progress with scratch amount (simplified for tap/drag)
        // For now, let's use a Long Press or Drag to simulate rubbing
        
        return ZStack {
            if isPolished {
                // Polished Gem with Text
                VStack(spacing: 5) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 40))
                        .foregroundColor(color)
                        .shadow(color: color.opacity(0.8), radius: 10, x: 0, y: 0)
                    
                    Text(getGemText(for: index))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Rough Stone
                ZStack {
                    Circle() // Rough shape placeholder
                        .fill(Color.gray)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                    
                    Image(systemName: "hexagon.fill") // Rough texture look
                        .font(.system(size: 50))
                        .foregroundColor(.black.opacity(0.3))
                }
                .overlay(
                    // Show progress if we wanted to implement drag
                    Color.white.opacity(gemScratchAmount[index] * 0.5)
                        .mask(Circle())
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            // Rubbing effect
                            if gemScratchAmount[index] < 1.0 {
                                gemScratchAmount[index] += 0.05 // Increment polish
                                if gemScratchAmount[index] >= 1.0 {
                                    handleGemPolished(index: index)
                                }
                            }
                        }
                )
                // Fallback Tap for easier testing
                .onTapGesture {
                     if gemScratchAmount[index] < 1.0 {
                         gemScratchAmount[index] += 0.2
                         if gemScratchAmount[index] >= 1.0 {
                             handleGemPolished(index: index)
                         }
                     }
                }
            }
        }
        .frame(width: 100, height: 100)
    }
    
    func handleGemPolished(index: Int) {
        withAnimation(.easeOut(duration: 0.8)) {
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
    
    func getGemText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
