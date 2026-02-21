import SwiftUI

struct ScratchEffectView<Content: View>: View {
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    @State private var scratchPaths: [Int: [CGPoint]] = [:] // Store swipe points
    
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
            
            // Scratch Overlay
            if !isRevealed {
                scratchOverlay
            }
        }
    }
    
    var scratchOverlay: some View {
            ZStack {
                // Scratched "Holes" (Masking logic simulated)
                // We divide the card into 4 scratchable zones.
                
                // 1. Name Area
                scratchArea(index: 0, rect: CGRect(x: 20, y: 50, width: 250, height: 80))
                
                // 2. Age/Details Area
                scratchArea(index: 1, rect: CGRect(x: 20, y: 150, width: 200, height: 80))
                
                // 3. Distance Area
                scratchArea(index: 2, rect: CGRect(x: 20, y: 250, width: 200, height: 80))
                
                // 4. Photo/Face Area
                scratchArea(index: 3, rect: CGRect(x: 100, y: 100, width: 150, height: 150))
                
                // Hint
                if poppedIndices.isEmpty {
                    VStack {
                        Spacer()
                        Text("Scratch to Reveal!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                }
            }
            .cornerRadius(20)
    }
    
    func scratchArea(index: Int, rect: CGRect) -> some View {
        ZStack {
            if !poppedIndices.contains(index) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.gray, .silver, .gray]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: rect.width, height: rect.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: "sparkles")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.title)
                    )
                    .shadow(radius: 2)
                    // Swipe Gesture
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onEnded { _ in
                                handleScratch(index: index)
                            }
                    )
            }
        }
        .position(x: rect.midX, y: rect.midY)
    }
    
    func handleScratch(index: Int) {
        SoundManager.shared.playSound(named: "ScratchEffectView")
        
        withAnimation(.easeOut(duration: 0.5)) {
            _ = poppedIndices.insert(index)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Auto reveal if most scratched
        if poppedIndices.count >= 4 { // Logic check: scratchPoppedIndices only has 0...3 if we define 4 areas
             withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                 isRevealed = true
             }
        }
    }
}

extension Color {
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
}
