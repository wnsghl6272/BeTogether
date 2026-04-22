import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @StateObject private var notifManager = NotificationManager.shared
    @State private var showPreferences = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Navigation
                HStack {
                // Logo / Brand (Selected State)
                Text("HONSYL")
                    .font(.custom("ArialRoundedMTBold", size: 24))
                    .foregroundColor(.btTeal)
                    .shadow(color: .btTeal.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                HStack(spacing: 16) {
                    // Alerts Icon
                    NavigationLink(destination: NotificationView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                            
                            if notifManager.unreadCount > 0 {
                                Text("\(notifManager.unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 8, y: -6)
                            }
                        }
                    }
                    
                    // Matching Preferences
                    Button(action: { showPreferences = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.btIvory)
            
            // AI Chat Interface
            AiChatInterfaceView()
                .padding(.top, 10)
                .background(Color.btIvory)
            }
            .background(Color.btIvory)
            .navigationBarHidden(true)
            .sheet(isPresented: $showPreferences) {
                MatchingPreferenceEditView()
            }
            .onAppear {
                Task {
                    let lat = PermissionManager.shared.currentLocation?.coordinate.latitude ?? 0.0
                    let lon = PermissionManager.shared.currentLocation?.coordinate.longitude ?? 0.0
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let nowStr = formatter.string(from: Date())
                    
                    do {
                        try await AuthManager.shared.updateProfile(data: [
                            "last_active_at": nowStr,
                            "latitude": lat,
                            "longitude": lon
                        ])
                    } catch {
                        print("Failed to update activity status: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
}
