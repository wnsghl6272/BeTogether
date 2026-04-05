import SwiftUI

struct MatchesView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                DailyPicksView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Explore")
                        .font(.btHeader)
                }
            }
        }
    }
}

// MARK: - Subviews

struct DailyPicksView: View {
    @State private var dailyPicks: [(user: User, isUnlocked: Bool)] = []
    @State private var isLoading = true
    @State private var showPremiumAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                Text("Today's Top Picks For You")
                    .font(.btHeader)
                    .padding(.top, 10)
                
                Text("We found 2 users that match your vibe.\nCome back in 24 hours for new picks!")
                    .font(.btSubheader)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                
                if isLoading {
                    ProgressView()
                        .padding(.top, 50)
                } else if dailyPicks.isEmpty {
                    Text("No recommendations found.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    ForEach(dailyPicks.indices, id: \.self) { index in
                        let pick = dailyPicks[index]
                        DailyPickCardView(user: pick.user, isUnlocked: pick.isUnlocked) {
                            unlock(user: pick.user, at: index)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
        .onAppear { loadPicks() }
        .alert(isPresented: $showPremiumAlert) {
            Alert(
                title: Text("Premium Feature"),
                message: Text("You have used your 1 free unlock for today. Upgrade to Premium to unlock more Daily Picks!"),
                dismissButton: .default(Text("Got It"))
            )
        }
    }
    
    private func loadPicks() {
        Task {
            do {
                let picks = try await InteractionManager.shared.fetchDailyPicks()
                await MainActor.run {
                    self.dailyPicks = picks
                    self.isLoading = false
                }
            } catch {
                print("Error loading daily picks: \(error)")
                await MainActor.run { self.isLoading = false }
            }
        }
    }
    
    private func unlock(user: User, at index: Int) {
        guard let targetId = user.supabaseId else { return }
        Task {
            do {
                let success = try await InteractionManager.shared.unlockDailyPick(targetUserId: targetId)
                await MainActor.run {
                    if success {
                        withAnimation(.spring()) {
                            dailyPicks[index].isUnlocked = true
                        }
                    } else {
                        showPremiumAlert = true
                    }
                }
            } catch {
                print("Error unlocking: \(error)")
            }
        }
    }
}


struct DailyPickCardView: View {
    let user: User
    let isUnlocked: Bool
    let onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image
            if user.imageName.hasPrefix("http") {
                SimulatorSafeAsyncImage(url: URL(string: user.imageName)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                } errorView: { _ in
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Image(user.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Blur Effect if Locked
            if !isUnlocked {
                VisualEffectBlur(blurStyle: .regular)
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Overlay Content
            VStack {
                Spacer()
                
                // Info Box
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(isUnlocked ? "\(user.name), \(user.age)" : "??? , \(user.age)")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                            
                        HStack(spacing: 12) {
                            Label(user.mbti, systemImage: "brain.head.profile")
                            Label("\(user.distance) km", systemImage: "location.fill")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 5)
                    }
                    Spacer()
                }
                .padding()
                // A subtle gradient to make text readable even when image is unlocked
                .background(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
            }
            .frame(height: 380)
            
            // The Unlock Button or Verified Badge
            if !isUnlocked {
                VStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        
                    Text("Locked")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                        
                    Button(action: onUnlock) {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Unlock Profile")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.btTeal)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                    }
                    .padding(.top, 10)
                }
            } else {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.3)))
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 380)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}


#Preview {
    MatchesView()
}
