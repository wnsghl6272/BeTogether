import SwiftUI

struct SparkleEffectView<Content: View>: View {
    var user: User
    @Binding var isRevealed: Bool
    let content: () -> Content
    
    init(user: User, isRevealed: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.user = user
        self._isRevealed = isRevealed
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
            
            if !isRevealed {
                sparkleOverlay
            }
        }
    }
    
    var sparkleOverlay: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            // Calculate opacity: 1.0 when low on screen, 0.0 when high up
            // Adjust 700 and 200 based on typical screen height
            let opacity = max(0, min(1, (minY - 200) / 400))
            
            ZStack {
                Color.black.opacity(opacity * 0.8)
                
                if opacity > 0.1 {
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 10)
                        Text("Scroll Down to Reveal")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                    .opacity(opacity)
                }
            }
            .cornerRadius(20)
            .onChange(of: opacity) { oldValue, newValue in
                if newValue <= 0.05 {
                    if !isRevealed {
                         // SoundManager.shared.playSound(named: "SparkleEffectView") // File missing
                    }
                    isRevealed = true
                } else {
                    isRevealed = false
                }
            }
        }
    }
}
