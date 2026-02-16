import SwiftUI

struct NeonSignEffectView<Content: View>: View {
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
            
            // Neon Sign Overlay
            if !isRevealed {
                neonSignOverlay
            }
        }
    }
    
    var neonSignOverlay: some View {
        ZStack {
            // Reusing Fog Layers Logic for Background Fog
            // 4 Fog Layers that disappear as neon signs are lit
            ForEach(0..<4) { index in
                if poppedIndices.count <= index {
                    Color.white.opacity(0.15)
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
                }
            }
            
            // Dark Background for Neon Contrast
            Color.black.opacity(0.6)
                .allowsHitTesting(false)
            
            // Base frosting
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                .opacity(Double(4 - poppedIndices.count) / 4.0)
                .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
            
            VStack {
                Text("Light Up the Signs!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                    .shadow(color: .white, radius: 5)
                    .opacity(poppedIndices.count == 4 ? 0 : 1)
                Spacer()
            }
            
            VStack(spacing: 20) {
                neonBox(text: "NAME: \(user.name)", index: 0, color: .pink)
                neonBox(text: "AGE: \(user.age)", index: 1, color: .cyan)
                neonBox(text: "MBTI: \(user.mbti)", index: 2, color: .purple)
                neonBox(text: "DIST: \(user.distance)km", index: 3, color: .green)
            }
        }
        .cornerRadius(20)
    }
    
    func neonBox(text: String, index: Int, color: Color) -> some View {
        let isLit = poppedIndices.contains(index)
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                _ = poppedIndices.insert(index)
            }
            
            // Vibration feedback could go here
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            if poppedIndices.count == 4 {
                withAnimation(.easeInOut(duration: 2.5).delay(1.0)) {
                    isRevealed = true
                }
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isLit ? color : Color.gray.opacity(0.5), lineWidth: isLit ? 3 : 1)
                    .background(isLit ? color.opacity(0.1) : Color.black.opacity(0.3))
                    .cornerRadius(15)
                    .frame(width: 250, height: 60)
                    .shadow(color: isLit ? color : .clear, radius: isLit ? 10 : 0)
                
                if isLit {
                    Text(text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundColor(color)
                        .shadow(color: color, radius: 5)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("TAP TO LIGHT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .fontDesign(.monospaced)
                        .foregroundColor(.gray)
                }
            }
        }
        .disabled(isLit)
    }
}
