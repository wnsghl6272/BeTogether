import SwiftUI

struct NotificationPermissionView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var isSaving: Bool = false
    
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
                    if isSaving {
                        ProgressView()
                            .padding(.bottom, 5)
                    }
                    
                    BTButton(title: "Allow Notifications") {
                        Task {
                            await PermissionManager.shared.requestNotificationPermission()
                            continueToNextStep()
                        }
                    }
                    .disabled(isSaving)
                    
                    Button("Maybe Later") {
                        continueToNextStep()
                    }
                    .font(.body)
                    .foregroundColor(.gray)
                    .disabled(isSaving)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func continueToNextStep() {
        isSaving = true
        Task {
            do {
                try await AuthManager.shared.updateProfile(data: ["onboarding_step": "locationPermission"])
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .locationPermission)
                }
            } catch {
                print("Error saving step: \(error)")
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .locationPermission)
                }
            }
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environmentObject(UserSessionViewModel())
}
