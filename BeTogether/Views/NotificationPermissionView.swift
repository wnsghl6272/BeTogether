import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon / Illustration
                ZStack {
                    Circle()
                        .fill(Color.btTeal.opacity(0.1))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.btTeal)
                }
                
                VStack(spacing: 16) {
                    Text("Don't miss a match!")
                        .font(.btHeader)
                        .foregroundColor(.btTeal)
                    
                    Text("Turn on notifications to get notified when\nsomeone likes you or sends a message.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    BTButton(title: "Allow Notifications") {
                        // In a real app, request permission here
                        // UNUserNotificationCenter.current().requestAuthorization...
                        userSession.advanceToNextStep()
                    }
                    
                    Button("Maybe Later") {
                        userSession.advanceToNextStep()
                    }
                    .font(.body)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(UserSessionViewModel())
}
