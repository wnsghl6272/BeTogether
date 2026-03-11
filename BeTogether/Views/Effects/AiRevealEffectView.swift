import SwiftUI

struct AiRevealEffectView<Content: View>: View {
    let user: User
    let candidateReasons: [String] // 4 reasons
    @Binding var isRevealed: Bool
    @ViewBuilder var content: Content
    
    @State private var revealStep = 0 // 0 to 4
    @State private var showReasonsSheet = false
    
    // Blur amounts for each step
    let blurAmounts: [CGFloat] = [40, 25, 15, 8, 0]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Underneath content (The actual card)
            content
                .blur(radius: isRevealed ? 0 : blurAmounts[revealStep])
                .animation(.easeInOut(duration: 0.8), value: revealStep)
                .animation(.easeInOut(duration: 0.8), value: isRevealed)
            
            if !isRevealed {
                // Frost overlay
                Color.black.opacity(0.3)
                    .background(Material.ultraThin)
                    .opacity(1.0 - (Double(revealStep) * 0.25))
                    .cornerRadius(20)
                    .animation(.easeInOut(duration: 0.8), value: revealStep)
                
                // Content Overlay - uses ScrollView to prevent clipping
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("AI Matchmaker")
                                .font(.headline)
                                .foregroundColor(.btTeal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white)
                                .cornerRadius(12)
                            
                            Text("I found a great match!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            // Show reasons progressively
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(0..<min(revealStep + 1, 4), id: \.self) { index in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 13))
                                            .foregroundColor(index == revealStep ? .btTeal : .white.opacity(0.5))
                                            .padding(.top, 2)
                                        
                                        Text(candidateReasons.indices.contains(index) ? candidateReasons[index] : "")
                                            .font(.subheadline)
                                            .foregroundColor(index == revealStep ? .white : .white.opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .background(Color.black.opacity(index == revealStep ? 0.6 : 0.3))
                                    .cornerRadius(12)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .animation(.spring(), value: revealStep)
                        }
                        .padding(16)
                        .padding(.bottom, 8)
                    }
                    
                    // Reveal button – pinned at the bottom, never clipped
                    Button(action: advanceStep) {
                        Text(revealStep < 3 ? "Tap to Reveal More ✨" : "See Final Match 🎉")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.btTeal)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                // Give the overlay exactly the card height so it never overflows
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // ── POST-REVEAL: "Why this match?" pill in top-right corner ──
            if isRevealed {
                HStack {
                    Spacer()
                    Button(action: { showReasonsSheet = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .bold))
                            Text("Why this match?")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.btTeal.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: Color.btTeal.opacity(0.5), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 14)
                }
            }
        }
        .sheet(isPresented: $showReasonsSheet) {
            ReasonsSheetView(reasons: candidateReasons)
        }
    }
    
    private func advanceStep() {
        if revealStep < 3 {
            withAnimation { revealStep += 1 }
        } else {
            withAnimation(.easeInOut(duration: 0.6)) {
                revealStep = 4
                isRevealed = true
            }
        }
    }
}

// MARK: - Reasons Sheet (shown after full reveal)

struct ReasonsSheetView: View {
    let reasons: [String]
    @Environment(\.dismiss) private var dismiss
    
    private let stepIcons = ["heart.text.square.fill", "person.crop.circle.fill.badge.checkmark", "leaf.fill", "star.fill"]
    private let stepTitles = ["MBTI 궁합", "기본 매칭", "특성 매칭", "종합 추천"]
    private let stepColors: [Color] = [.purple, .blue, .green, .btTeal]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.btTeal)
                        Text("AI 추천 이유")
                            .font(.title2.bold())
                        Text("이 사람을 추천한 4가지 이유를 확인해보세요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)
                    
                    // Reason cards
                    ForEach(reasons.indices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(stepColors[index % stepColors.count].opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: stepIcons[index % stepIcons.count])
                                    .font(.system(size: 20))
                                    .foregroundColor(stepColors[index % stepColors.count])
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stepTitles[index % stepTitles.count])
                                    .font(.caption.bold())
                                    .foregroundColor(stepColors[index % stepColors.count])
                                    .textCase(.uppercase)
                                Text(reasons[index])
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.btTeal)
                }
            }
        }
    }
}
