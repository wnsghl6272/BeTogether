import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    let users: [User] = User.mockUsers
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation
            HStack {
                // Logo / Brand (Selected State)
                Text("BeTogether")
                    .font(.custom("ArialRoundedMTBold", size: 24))
                    .foregroundColor(.btTeal)
                    .shadow(color: .btTeal.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Center Menu (Dimmed) - REMOVED
                // HStack(spacing: 20) {
                //    Text("Discover")
                //        .foregroundColor(.gray.opacity(0.6))
                //        .font(.system(size: 16, weight: .medium))
                //    Text("Gathering")
                //        .foregroundColor(.gray.opacity(0.6))
                //        .font(.system(size: 16, weight: .medium))
                // }
                
                Spacer()
                
                // Settings Icon
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.btIvory)
            
            // Photo Card List
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                        PhotoCardView(user: user, effect: getEffect(for: index))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.btIvory)
        }
    }
    
    func getEffect(for index: Int) -> CardEffect {
        switch index {
        case 0: return .fog      // First card: Fog Effect
        case 1: return .scratch  // Second card: Scratch Effect
        case 2: return .heartPuzzle // Third card: Heart Puzzle Effect
        case 3: return .neonSign // Fourth card: Neon Sign Effect
        case 4: return .magnify // Fifth card: Magnifying Glass Effect
        case 5: return .curtain // Sixth card: Curtain Reveal Effect
        case 6: return .sparkleDust // Seventh card: Sparkle Dust Effect
        case 7: return .gemPolish // Eighth card: Gem Polish Effect
        case 8: return .envelopes // Ninth card: Message Note Effect
        case 9: return .underwater // Tenth card: Underwater Effect
        default: return .none    // Others: Normal
        }
    }

}

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
}
