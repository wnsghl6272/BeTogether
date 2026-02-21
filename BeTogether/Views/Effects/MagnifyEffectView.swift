import SwiftUI

struct MagnifyEffectView<Content: View>: View {
    let user: User
    @Binding var isRevealed: Bool
    let content: Content
    
    @State private var poppedIndices: Set<Int> = []
    @State private var itemPositions: [CGPoint] = []
    @State private var activeMagnifyItem: Int? = nil // Currently being magnified
    
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
            
            // Magnify Overlay
            if !isRevealed {
                magnifyOverlay
            }
        }
        .onAppear {
            if itemPositions.isEmpty {
                generateRandomPositions()
            }
        }
    }
    
    var magnifyOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Fog Layers
                ForEach(0..<4) { index in
                    if poppedIndices.count <= index {
                        Color.white.opacity(0.15)
                            .allowsHitTesting(false)
                            .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
                    }
                }
                
                // Base frosting
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                    .opacity(Double(4 - poppedIndices.count) / 4.0)
                    .animation(.easeInOut(duration: 0.8), value: poppedIndices.count)
                
                // Hints
                VStack {
                    Text("Find 4 Tiny Clues!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 40)
                        .opacity(poppedIndices.count == 4 ? 0 : 1)
                    Spacer()
                }
                .allowsHitTesting(false)
                
                // Tiny Items
                if !itemPositions.isEmpty {
                    ForEach(0..<4) { index in
                        if !poppedIndices.contains(index) {
                            magnifyItem(index: index, position: itemPositions[index])
                        }
                    }
                }
                
                // Magnifying Glass Effect (The Lens)
                if let activeIndex = activeMagnifyItem {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                // Dismiss if needed, but we auto-dismiss
                            }
                        
                        VStack(spacing: 15) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text(getItemText(for: activeIndex))
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 2, x: 0, y: 2)
                                .padding()
                                .background(Circle().fill(Color.white.opacity(0.2)).blur(radius: 5))
                        }
                        .scaleEffect(1.2)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(100)
                }
            }
        }
        .cornerRadius(20)
    }
    
    func magnifyItem(index: Int, position: CGPoint) -> some View {
        Button(action: {
            SoundManager.shared.playSound(named: "MagnifyEffectView")
            
            // Trigger Magnify
            withAnimation(.spring()) {
                activeMagnifyItem = index
            }
            
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Auto dismiss and clear fog
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    activeMagnifyItem = nil
                    _ = poppedIndices.insert(index)
                }
                
                if poppedIndices.count == 4 {
                    withAnimation(.easeInOut(duration: 2.5).delay(1.0)) {
                        isRevealed = true
                    }
                }
            }
        }) {
            Text(getItemText(for: index))
                .font(.system(size: 8)) // Very tiny!
                .foregroundColor(.white.opacity(0.5)) // Hard to see
                .frame(width: 40, height: 20)
                .background(Color.black.opacity(0.2)) // Slight background to be tappable
                .cornerRadius(4)
                .rotationEffect(.degrees(Double.random(in: -20...20)))
        }
        .position(position)
    }
    
    func generateRandomPositions() {
        // Generate 4 random positions within the card frame (approx 300x500 safe area)
        // Avoid edges
        var positions: [CGPoint] = []
        for _ in 0..<4 {
            let x = CGFloat.random(in: 50...300) // approx width range
            let y = CGFloat.random(in: 100...450) // approx height range
            positions.append(CGPoint(x: x, y: y))
        }
        itemPositions = positions
    }
    
    func getItemText(for index: Int) -> String {
        switch index {
        case 0: return user.name
        case 1: return "\(user.age)"
        case 2: return user.mbti
        case 3: return "\(user.distance)km"
        default: return ""
        }
    }
}
