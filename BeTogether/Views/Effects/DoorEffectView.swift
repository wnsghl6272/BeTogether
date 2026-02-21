import SwiftUI

struct DoorEffectView<Content: View>: View {
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
            
            doorOverlay
        }
        .onTapGesture {
            // SoundManager.shared.playSound(named: "DoorEffectView") // File missing
            
            withAnimation(.easeInOut(duration: 2.5)) {
                isRevealed = true
            }
        }
    }
    
    var doorOverlay: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Door
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.btTeal.opacity(0.8), .btTeal]), startPoint: .leading, endPoint: .trailing)
                    
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: geometry.size.width / 2, height: geometry.size.height)
                .rotation3DEffect(
                    .degrees(isRevealed ? -100 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.5
                )
                
                // Right Door
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [.btTeal, .btTeal.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: geometry.size.width / 2, height: geometry.size.height)
                .rotation3DEffect(
                    .degrees(isRevealed ? 100 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .trailing,
                    perspective: 0.5
                )
            }
        }
        .cornerRadius(20)
        .allowsHitTesting(!isRevealed)
        .opacity(isRevealed ? 0 : 1)
        .animation(.easeInOut(duration: 2.5).delay(0.2), value: isRevealed)
    }
}
