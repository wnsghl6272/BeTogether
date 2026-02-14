import SwiftUI

enum CardEffect {
    case none
    case fog      // Tap to reveal (Foggy overlay)
    case sparkle  // Scroll to reveal (Sparkling overlay)
    case blur     // Tap to reveal (Blur measurement)
    case curtain  // Tap to reveal (Curtain opening)
    case door     // Tap to reveal (3D Door opening)
    case popReveal // Gamified: Pop bubbles to reveal info
}

struct PhotoCardView: View {
    let user: User
    var effect: CardEffect = .none
    @State private var isRevealed: Bool = false
    
    // For Pop Reveal Effect
    @State private var poppedBubbles: Set<Int> = [] // 0: Name, 1: Age, 2: Distance
    
    // For Enhanced Fog Effect
    @State private var fogPoppedIndices: Set<Int> = [] // 0: Name, 1: Age, 2: MBTI, 3: Distance
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main Card Content
            mainCardContent
                // Blur Logic:
                // Fog: Blurred until all 4 fog bubbles popped.
                // Blur: Blurred standard tap.
                // PopReveal: Blurred until 3 bubbles popped.
                .blur(radius:
                        (effect == .fog && fogPoppedIndices.count < 4) ? 20 :
                        (effect == .blur && !isRevealed && effect != .popReveal) ? 20 :
                        (effect == .popReveal && poppedBubbles.count < 3) ? 15 : 0
                )
                .animation(.easeInOut(duration: 2.5), value: isRevealed)
                .animation(.easeInOut(duration: 2.0), value: poppedBubbles.count)
                .animation(.easeInOut(duration: 2.0), value: fogPoppedIndices.count)
                .zIndex(0) // Ensure content is behind
            
            // Interaction Overlays
            Group {
                switch effect {
                case .fog:
                    if !isRevealed {
                        fogOverlay
                    }
                case .curtain:
                    if !isRevealed {
                        curtainOverlay
                            .transition(.move(edge: .top).animation(.easeInOut(duration: 2.5)))
                    }
                case .sparkle:
                    if !isRevealed {
                        sparkleOverlay
                    }
                case .door:
                    doorOverlay // Keeps view for 3D animation
                case .popReveal:
                    if !isRevealed {
                        popRevealOverlay
                    }
                default:
                    EmptyView()
                }
            }
            .zIndex(1) // Ensure overlay stays on top during transition
        }
        .frame(height: 580)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        .onTapGesture {
            // General tap to reveal for simple effects
            if effect == .blur || effect == .curtain || effect == .door {
                withAnimation(.easeInOut(duration: 2.5)) { 
                    isRevealed = true
                }
            }
        }
    }
    
    // MARK: - Main Content
    var mainCardContent: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            GeometryReader { geometry in
                Image(user.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .cornerRadius(20)
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(20)
            
            // Info Content
            VStack(alignment: .leading, spacing: 6) {
                // Online Status Badge
                if user.isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                }
                
                // Name and Age
                HStack(alignment: .firstTextBaseline) {
                    Text(user.name)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("\(user.age)")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.btTeal)
                            .font(.system(size: 18))
                    }
                }
                
                // Region and Distance
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(user.region) • \(user.distance)km away")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // MBTI Tag
                Text(user.mbti)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.btTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding(.top, 4)
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.gray.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    
                    Button(action: {}) {
                        Text("Add Friend")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.btTeal)
                            .cornerRadius(27.5)
                            .shadow(color: .btTeal.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(LinearGradient(gradient: Gradient(colors: [.pink, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                            .shadow(color: .pink.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.top, 15)
            }
            .padding(20)
            .padding(.bottom, 10)
            .opacity(isRevealed ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isRevealed) 
        }
    }
    
    // MARK: - Overlays
    
    // 1. Fog Overlay (Updated with 4 Balloons)
    var fogOverlay: some View {
        ZStack {
            Color.white.opacity(0.4)
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
            
            VStack {
                Text("Pop 4 Balloons!")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                Spacer()
            }
            
            // Randomly placed balloons or structured? Let's do structured random-ish.
            VStack(spacing: 20) {
                HStack(spacing: 30) {
                    fogBalloon(text: user.name, index: 0, color: .pink)
                        .offset(y: 20)
                    fogBalloon(text: "\(user.age)", index: 1, color: .orange)
                        .offset(y: -10)
                }
                HStack(spacing: 40) {
                    fogBalloon(text: user.mbti, index: 2, color: .purple)
                        .offset(y: 10)
                    fogBalloon(text: "\(user.distance)km", index: 3, color: .blue)
                        .offset(y: 30)
                }
            }
        }
        .cornerRadius(20)
    }
    
    func fogBalloon(text: String, index: Int, color: Color) -> some View {
        let isPopped = fogPoppedIndices.contains(index)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                _ = fogPoppedIndices.insert(index)
            }
            
            if fogPoppedIndices.count == 4 {
                // Wait for the last balloon's pop animation to be visible/enjoyed before revealing the photo
                withAnimation(.easeInOut(duration: 2.5).delay(1.5)) {
                    isRevealed = true
                }
            }
        }) {
            ZStack {
                if isPopped {
                    // Popped State: Text floats up and fades
                    Text(text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                        .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                } else {
                    // Balloon State
                    VStack(spacing: 0) {
                        Circle()
                            .fill(
                                LinearGradient(gradient: Gradient(colors: [color.opacity(0.8), color]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 80, height: 90)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: color.opacity(0.4), radius: 5, x: 0, y: 5)
                        
                        // String
                        Path { path in
                            path.move(to: CGPoint(x: 10, y: 0))
                            path.addCurve(to: CGPoint(x: 10, y: 30), control1: CGPoint(x: 0, y: 15), control2: CGPoint(x: 20, y: 15))
                        }
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(width: 20, height: 30)
                    }
                    .transition(.scale)
                }
            }
        }
        .disabled(isPopped)
        // Add floating animation if time permits, for now static is okay or simple appear.
    }
    
    // 2. Curtain Overlay
    var curtainOverlay: some View {
        ZStack {
            Color.btTeal
            
            VStack {
                Spacer()
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .padding()
                Text("Tap to Open Gift")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .cornerRadius(20)
        .transition(.move(edge: .top))
        .allowsHitTesting(false)
    }
    
    // 3. Sparkle Scroll Overlay
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
        }
    }
    
    // 4. Door Overlay
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
        .animation(.easeInOut(duration: 2.5).delay(0.2), value: isRevealed) // Fade out slightly after opening starts? Or just simple fade?
    }

    // 5. Pop Reveal Overlay
    var popRevealOverlay: some View {
        ZStack {
            // Fog background
            Color.white.opacity(0.3)
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

// Helper for Visual Blur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

#Preview {
    PhotoCardView(user: User.mockUsers[0], effect: .fog)
        .padding()
        .background(Color.btIvory)
}
