import SwiftUI

struct StoreView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var store = StoreManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Current Balance
                    HStack {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 32))
                        Text("\(store.economy?.coins ?? 0)")
                            .font(.system(size: 36, weight: .bold))
                    }
                    .padding(.top, 16)
                    
                    // Premium Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("BeTogether Premium")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                            if store.economy?.premiumStatus == true {
                                Text("Active")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .foregroundColor(.purple)
                                    .cornerRadius(12)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            FeatureRow(icon: "calendar.badge.plus", text: "10 Daily Check-in Coins")
                            FeatureRow(icon: "eye.fill", text: "See who liked you for FREE")
                            FeatureRow(icon: "gift.fill", text: "Free Daily Pick Unlocks")
                            FeatureRow(icon: "star.fill", text: "Priority Ai Matchmaking")
                        }
                        .foregroundColor(.white)
                        
                        if store.economy?.premiumStatus != true {
                            Button(action: {
                                Task {
                                    await store.purchasePremium()
                                }
                            }) {
                                Text("Subscribe for $9.99/mo")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.purple, Color.indigo]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    // Coin Bundles
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Get More Coins")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            CoinBundleCard(coins: 10, price: "$0.99") {
                                Task { await store.purchaseCoins(amount: 10) }
                            }
                            CoinBundleCard(coins: 50, price: "$3.99") {
                                Task { await store.purchaseCoins(amount: 50) }
                            }
                            CoinBundleCard(coins: 100, price: "$6.99", isPopular: true) {
                                Task { await store.purchaseCoins(amount: 100) }
                            }
                            CoinBundleCard(coins: 250, price: "$14.99") {
                                Task { await store.purchaseCoins(amount: 250) }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct CoinBundleCard: View {
    let coins: Int
    let price: String
    var isPopular: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if isPopular {
                    Text("POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .offset(y: -10)
                        .padding(.bottom, -15)
                }
                
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 32))
                
                Text("\(coins) Coins")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.btTeal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.btTeal.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isPopular ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
