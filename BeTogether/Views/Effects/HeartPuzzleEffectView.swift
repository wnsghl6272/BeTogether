import SwiftUI

struct HeartPuzzleEffectView<Content: View>: View {
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    
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
            
            // Heart Puzzle Overlay
            if !isRevealed {
                heartPuzzleOverlay
            }
        }
    }
    
    var heartPuzzleOverlay: some View {
        ZStack {
            // Background
            Color.pink.opacity(0.1)
                .allowsHitTesting(false)
            
            // 4 Puzzle Pieces forming a heart
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    puzzlePiece(index: 0, offsetX: 5, offsetY: 5)
                    puzzlePiece(index: 1, offsetX: -5, offsetY: 5)
                }
                HStack(spacing: 0) {
                    puzzlePiece(index: 2, offsetX: 5, offsetY: -5)
                    puzzlePiece(index: 3, offsetX: -5, offsetY: -5)
                }
            }
            .rotationEffect(.degrees(45)) // Rotate to look like a heart (diamond shape logic)
            // Or use better positioning
            
            if poppedIndices.isEmpty {
                Text("Collect the Heart Pieces!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .padding(.top, 250)
            }
        }
    }
    
    func puzzlePiece(index: Int, offsetX: CGFloat, offsetY: CGFloat) -> some View {
        let isPopped = poppedIndices.contains(index)
        
        return Button(action: {
            handleHeartTap(index: index)
        }) {
            ZStack {
                if !isPopped {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.pink.opacity(0.8))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .shadow(radius: 5)
                        .offset(x: isPopped ? offsetX * 10 : 0, y: isPopped ? offsetY * 10 : 0)
                } else {
                     Color.clear.frame(width: 100, height: 100)
                }
            }
        }
        .disabled(isPopped)
    }
    
    func handleHeartTap(index: Int) {
        SoundManager.shared.playSound(named: "HeartPuzzleEffectView")
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            _ = poppedIndices.insert(index)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if poppedIndices.count == 4 {
            withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                isRevealed = true
            }
        }
    }
}
