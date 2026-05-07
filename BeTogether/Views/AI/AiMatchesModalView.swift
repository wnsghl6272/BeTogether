import SwiftUI

/// Modal view displaying AI-recommended matches with card-swiping interface.
struct AiMatchesModalView: View {
    @Binding var matchedUsers: [User]
    @Binding var matchReasonsArray: [[String]]
    @Binding var showMatchesModal: Bool
    let matchedByPreference: Bool
    let onAction: (String, User) -> Void
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with close button
                    HStack {
                        Text("AI Recommendations (\(matchedUsers.count))")
                            .font(.headline)
                            .padding(.horizontal, 16)
                        Spacer()
                        Button(action: { showMatchesModal = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 20)
                    
                    if matchedByPreference {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.green)
                            Text("We found perfect matches based on your preferences! ✨")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 14)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("It seems your perfect match is away, so we slightly broadened your criteria to find someone you might click with!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(8)
                        .padding(.horizontal, 14)
                    }
                    
                    if let firstUser = matchedUsers.first, let firstReason = matchReasonsArray.first {
                        PhotoCardView(user: firstUser, effect: .aiReveal(reasons: firstReason)) { actionStr in
                            onAction(actionStr, firstUser)
                        }
                        .padding(.horizontal, 14)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                        .id(firstUser.id)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }
}
