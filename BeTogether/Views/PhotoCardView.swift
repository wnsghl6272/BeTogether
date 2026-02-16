import SwiftUI

enum CardEffect {
    case none
    case fog      // Tap to reveal (Foggy overlay)
    case sparkle  // Scroll to reveal (Sparkling overlay)
    case blur     // Tap to reveal (Blur measurement)
    case curtain  // Tap to reveal (Curtain opening)
    case door     // Tap to reveal (3D Door opening)
    case popReveal // Gamified: Pop bubbles to reveal info
    case scratch  // Scratch card effect
    case heartPuzzle // Heart puzzle effect
    case neonSign // Neon sign effect
    case magnify // Magnifying glass effect
    case sparkleDust // Sparkle dust effect (7th card)
    case gemPolish // Gem polishing effect (8th card)
    case envelopes // Message note effect (9th card)
    case underwater // Underwater effect (10th card)
}

struct PhotoCardView: View {
    let user: User
    var effect: CardEffect = .none
    @State private var isRevealed: Bool = false
    
    

    

    

    

    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if effect == .underwater {
                UnderwaterEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .fog {
                FogEffectView(isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .scratch {
                ScratchEffectView(isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .heartPuzzle {
                HeartPuzzleEffectView(isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .neonSign {
                NeonSignEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .magnify {
                MagnifyEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .curtain {
                CurtainEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .sparkleDust {
                SparkleDustEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .gemPolish {
                GemPolishEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .envelopes {
                EnvelopesEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .popReveal {
                PopRevealEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .door {
                DoorEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .sparkle {
                SparkleEffectView(user: user, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else if effect == .blur {
                BlurEffectView(isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else {
                // Main Card Content (fallback)
                mainCardContent
                    .zIndex(0)
            }
            
            // Interaction Overlays
            Group {
                switch effect {




                default:
                    EmptyView()
                }
            }
            .zIndex(1) // Ensure overlay stays on top during transition
        }
        .frame(height: 580)
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)


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
            .opacity((effect == .none || effect == .sparkle || isRevealed) ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isRevealed) 
        }
    }
}

#Preview {
    PhotoCardView(user: User.mockUsers[0], effect: .fog)
        .padding()
        .background(Color.btIvory)
}
