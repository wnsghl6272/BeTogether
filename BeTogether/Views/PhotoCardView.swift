import SwiftUI

enum CardEffect {
    case none
    case fog      // Tap to reveal (Foggy overlay)
    case sparkle  // Scroll to reveal (Sparkling overlay)
    case blur     // Tap to reveal (Blur measurement)
    case curtain  // Tap to reveal (Curtain opening)
    case door     // Tap to reveal (3D Door opening)
}

struct PhotoCardView: View {
    let user: User
    var effect: CardEffect = .none
    @State private var isRevealed: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main Card Content
            mainCardContent
                .blur(radius: (effect == .blur && !isRevealed) ? 20 : 0) // Blur Effect Logic
                .animation(.easeInOut(duration: 2.5), value: isRevealed) // Slower blur transition
                .zIndex(0) // Ensure content is behind
            
            // Interaction Overlays
            Group {
                switch effect {
                case .fog:
                    if !isRevealed {
                        fogOverlay
                            .transition(.opacity.animation(.easeInOut(duration: 2.0)))
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
                default:
                    EmptyView()
                }
            }
            .zIndex(1) // Ensure overlay stays on top during transition
        }
        .frame(height: 580)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
        .onTapGesture {
            if effect == .fog || effect == .blur || effect == .curtain || effect == .door {
                withAnimation(.easeInOut(duration: 2.5)) { // Global slow reveal
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
        }
    }
    
    // MARK: - Overlays
    
    // 1. Fog Overlay
    var fogOverlay: some View {
        ZStack {
            Color.white.opacity(0.4)
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
            
            VStack {
                Image(systemName: "hand.tap.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("Tap to Wipe Fog")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .cornerRadius(20)
        .allowsHitTesting(false) // Let tap gesture pass through
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
        // Actually, let's just rely on rotation. If we want it gone, we can fade it out too.
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
