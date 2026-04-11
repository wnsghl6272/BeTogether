import SwiftUI

struct NotificationAlertOverlay: View {
    @StateObject private var notifManager = NotificationManager.shared
    
    var body: some View {
        ZStack {
            if let alert = notifManager.activeAlert {
                // Dim background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        dismiss()
                    }
                
                // Popup Content
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .font(.headline)
                        }
                    }
                    
                    Text(alert.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if alert.isPremiumMockup {
                        // Blurred representation
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.white)
                                .blur(radius: 8)
                        }
                        
                        Text("???")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Someone liked you!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            // Premium Feature Stub
                            dismiss()
                            print("Premium stub: Open See Who Liked Me")
                        }) {
                            Text("See who liked me")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.btTeal)
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    } else {
                        Text(alert.message)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(), value: notifManager.activeAlert != nil)
    }
    
    private func dismiss() {
        withAnimation {
            notifManager.activeAlert = nil
        }
    }
}

#Preview {
    NotificationAlertOverlay()
        .onAppear {
            NotificationManager.shared.activeAlert = AppNotification(
                title: "New Like!",
                message: "Someone liked you.",
                isPremiumMockup: true
            )
        }
}
