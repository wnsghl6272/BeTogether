import SwiftUI

struct LocationPermissionView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @StateObject private var permissionManager = PermissionManager.shared
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
                    
                    Image(systemName: "location.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.btTeal)
                }
                
                VStack(spacing: 16) {
                    Text("Find verified people nearby")
                        .font(.btHeader)
                        .foregroundColor(.btTeal)
                    
                    Text("We use your location to recommend\ncompatible matches in your area.")
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
                    
                    BTButton(title: "Allow Location Access") {
                        if permissionManager.locationStatus == .notDetermined {
                            permissionManager.requestLocationPermission()
                        } else {
                            continueToNextStep()
                        }
                    }
                    .disabled(isSaving)
                    .onChange(of: permissionManager.locationStatus) { oldStatus, newStatus in
                        if newStatus != .notDetermined {
                            continueToNextStep()
                        }
                    }
                    
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
                try await AuthManager.shared.updateProfile(data: ["onboarding_step": "terms"])
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .terms)
                }
            } catch {
                print("Error saving step: \(error)")
                await MainActor.run {
                    isSaving = false
                    router.navigate(to: .terms)
                }
            }
        }
    }
}

#Preview {
    LocationPermissionView()
        .environmentObject(UserSessionViewModel())
}
