import SwiftUI

struct PopRevealEffectView<Content: View>: View {
    var user: User
    @Binding var isRevealed: Bool
    let content: () -> Content
    
    @State private var poppedBubbles: Set<Int> = [] // 0: Name, 1: Age, 2: Distance
    
    init(user: User, isRevealed: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.user = user
        self._isRevealed = isRevealed
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .blur(radius: poppedBubbles.count < 3 ? 15 : 0)
                .animation(.easeInOut(duration: 2.0), value: poppedBubbles.count)
            
            if !isRevealed {
                popRevealOverlay
                    .transition(.opacity)
            }
        }
    }
    
    var popRevealOverlay: some View {
        ZStack {
            // Fog background
            Color.white.opacity(0.01)
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
            
            VStack(spacing: 30) {
                Text("Tap bubbles to find out!")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                
                Spacer()
                
                // Bubble 1: Name
                infoBubble(icon: "person.fill", text: user.name, index: 0)
                
                // Bubble 2: Age
                infoBubble(icon: "calendar", text: "\(user.age) years old", index: 1)
                
                // Bubble 3: Distance
                infoBubble(icon: "location.fill", text: "\(user.distance)km away", index: 2)
                
                Spacer()
            }
        }
        .cornerRadius(20)
    }
    
    func infoBubble(icon: String, text: String, index: Int) -> some View {
        let isPopped = poppedBubbles.contains(index)
        
        return Button(action: {
            // SoundManager.shared.playSound(named: "PopRevealEffectView") // File missing
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                _ = poppedBubbles.insert(index)
            }
            
            if poppedBubbles.count == 3 {
                 // Wait for the last bubble's pop animation to be visible before revealing the photo
                withAnimation(.easeInOut(duration: 2.5).delay(1.5)) {
                    isRevealed = true
                }
            }
        }) {
            ZStack {
                if isPopped {
                    // Revealed State
                    HStack {
                        Image(systemName: icon)
                        Text(text)
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.btTeal)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(30)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Hidden State (Bubble)
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.btTeal, .blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "questionmark")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                        .shadow(color: .btTeal.opacity(0.5), radius: 10, x: 0, y: 5)
                }
            }
        }
        .disabled(isPopped)
    }
}
