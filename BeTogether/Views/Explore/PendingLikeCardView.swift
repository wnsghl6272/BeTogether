import SwiftUI

struct PendingLikeCardView: View {
    let user: User
    let onLikeBack: (User) -> Void
    @State private var isUnlocked = false
    @State private var showCoinAlert = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ProfileAvatarView(imageUrl: user.imageName)
                    .blur(radius: isUnlocked ? 0 : 12)
                    .clipShape(Circle())
                
                Text(isUnlocked ? user.name : "???")
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                if isUnlocked {
                    Button("Like Back") {
                        onLikeBack(user)
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.pink)
                    .cornerRadius(15)
                } else {
                    Button(action: {
                        Task {
                            let isPremium = StoreManager.shared.economy?.premiumStatus == true
                            if isPremium {
                                await MainActor.run {
                                    withAnimation(.spring()) {
                                        isUnlocked = true
                                    }
                                }
                            } else {
                                let success = await StoreManager.shared.spendCoins(amount: 1)
                                if success {
                                    await MainActor.run {
                                        withAnimation(.spring()) {
                                            isUnlocked = true
                                        }
                                    }
                                } else {
                                    await MainActor.run {
                                        showCoinAlert = true
                                    }
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 2) {
                            Text("Unlock")
                            Image(systemName: "bitcoinsign.circle.fill")
                                .foregroundColor(.yellow)
                            Text("1")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.btTeal)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.btTeal, lineWidth: 1))
                    }
                }
            }
            
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                    .shadow(radius: 2)
                    .offset(y: -25)
            }
        }
        .padding(10)
        .frame(width: 130, height: 165)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 4)
        .alert("Not Enough Coins", isPresented: $showCoinAlert) {
            Button("Got It", role: .cancel) {}
        } message: {
            Text("Unlocking who liked you costs 1 Coin. Tap the coin icon to get more, or upgrade to Premium for free unlocks!")
        }
    }
}
