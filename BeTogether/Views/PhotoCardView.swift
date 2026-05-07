import SwiftUI

enum CardEffect: Equatable {
    case none
    case aiReveal(reasons: [String]) // AI 4-step reveal effect
}

struct PhotoCardView: View {
    let user: User
    var effect: CardEffect = .none
    var reasons: [String] = []
    var onAction: ((String) -> Void)? = nil
    @State private var isRevealed: Bool = false
    @State private var currentImageIndex: Int = 0
    
    private var imagesToDisplay: [String] {
        user.imageNames.isEmpty ? [user.imageName] : user.imageNames
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if case let .aiReveal(reasons) = effect {
                AiRevealEffectView(user: user, candidateReasons: reasons, isRevealed: $isRevealed) {
                    mainCardContent
                }
                .zIndex(0)
            } else {
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
            .zIndex(1)
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
                            .frame(width: max(0, geometry.size.width), height: max(0, geometry.size.height))
                            .clipped()
                            .tag(index)
                        } else {
                            Image(imageUrl)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: max(0, geometry.size.width), height: max(0, geometry.size.height))
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
                if currentImageIndex == 0 {
                    // Page 1: Basic Info
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
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(user.region) • \(user.distance)km away")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(user.mbti)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.btTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.top, 4)
                        
                } else if currentImageIndex == 1 {
                    // Page 2: Lifestyle
                    Text("Lifestyle")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let lifestyle = user.lifestyle, !lifestyle.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(lifestyle.keys.prefix(4)), id: \.self) { key in
                                if let val = lifestyle[key] {
                                    Text("\(key): \(val)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    } else {
                        Text("No lifestyle info available yet.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                } else {
                    // Page 3+: Personality QA
                    Text("Q&A")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let qa = user.personalQA, !qa.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            let previewQA = Array(qa).prefix(2)
                            ForEach(previewQA, id: \.key) { item in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Q: \(item.key)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("A: \(item.value)")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    } else {
                        Text("No Q&A provided.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Action Buttons
                HStack(spacing: 20) {
                    Spacer()
                    
                    Button(action: { onAction?("pass") }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.gray.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    
                    Button(action: { onAction?("like") }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.btTeal)
                            .clipShape(Circle())
                            .shadow(color: .btTeal.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    
                    Button(action: {}) {
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
            .opacity((effect == .none || isRevealed) ? 1 : 0)
            .animation(.easeInOut(duration: 0.5), value: isRevealed) 
        }
    }
}
