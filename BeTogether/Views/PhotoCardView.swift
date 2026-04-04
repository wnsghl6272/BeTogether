import SwiftUI

enum CardEffect: Equatable {
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
    case aiReveal(reasons: [String]) // AI 4-step reveal effect
}

struct PhotoCardView: View {
    let user: User
    var effect: CardEffect = .none
    var onAction: ((String) -> Void)? = nil
    @State private var isRevealed: Bool = false
    @State private var currentImageIndex: Int = 0
    
    private var imagesToDisplay: [String] {
        user.imageNames.isEmpty ? [user.imageName] : user.imageNames
    }
    
    

    

    

    

    
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
            } else if case let .aiReveal(reasons) = effect {
                AiRevealEffectView(user: user, candidateReasons: reasons, isRevealed: $isRevealed) {
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
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(imagesToDisplay.enumerated()), id: \.offset) { index, imageUrl in
                        if imageUrl.hasPrefix("http") {
                            let encodedUrlStr = imageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? imageUrl
                            SimulatorSafeAsyncImage(url: URL(string: encodedUrlStr)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(ProgressView())
                            } errorView: { error in
                                VStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red)
                                    Text(error.localizedDescription)
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemGray6))
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .tag(index)
                        } else {
                            Image(imageUrl)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                                .tag(index)
                        }
                    }

                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .cornerRadius(20)
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(20)
            .allowsHitTesting(false)
            
            // Custom Top Page Indicator
            if imagesToDisplay.count > 1 {
                VStack {
                    HStack(spacing: 6) {
                        ForEach(0..<imagesToDisplay.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentImageIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .shadow(radius: 1)
                        }
                    }
                    .padding(.top, 16)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }
            
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
                    Spacer()
                    
                    // X Button (Pass)
                    Button(action: {
                        onAction?("pass")
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    
                    // Heart Button (Like)
                    Button(action: {
                        onAction?("like")
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.btTeal)
                            .clipShape(Circle())
                            .shadow(color: .btTeal.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    
                    // Sparkles Button (Super Like)
                    Button(action: {
                        // Super like is currently disabled
                    }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(LinearGradient(gradient: Gradient(colors: [.pink, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                            .shadow(color: .pink.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    .disabled(true)
                    .opacity(0.5)
                    
                    Spacer()
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

struct SimulatorSafeAsyncImage<Content: View, Placeholder: View, ErrorView: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let errorView: (Error) -> ErrorView

    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        ZStack {
            if isLoading {
                placeholder()
            } else if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else if let error = error {
                errorView(error)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url = url else {
                isLoading = false
                return
            }
            // Fetch anew instead of relying on default shared URLSession
            do {
                let session = URLSession(configuration: .ephemeral)
                let (data, _) = try await session.data(from: url)
                if let image = UIImage(data: data) {
                    self.uiImage = image
                } else {
                    self.error = URLError(.cannotDecodeRawData)
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}
