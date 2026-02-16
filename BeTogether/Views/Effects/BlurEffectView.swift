import SwiftUI

struct BlurEffectView<Content: View>: View {
    @Binding var isRevealed: Bool
    let content: () -> Content
    
    init(isRevealed: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isRevealed = isRevealed
        self.content = content
    }
    
    var body: some View {
        ZStack {
            content()
                .blur(radius: isRevealed ? 0 : 20)
                .animation(.easeInOut(duration: 2.5), value: isRevealed)
            
            if !isRevealed {
                Color.black.opacity(0.01) // Invisible tap target
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 2.5)) {
                            isRevealed = true
                        }
                    }
            }
        }
    }
}
