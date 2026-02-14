import SwiftUI

struct ProfileMainView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Profile Header
                VStack(spacing: 15) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    
                    Text("User Name") // Placeholder
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("MBTI: \(userSession.mbtiResult)")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.btTeal.opacity(0.1))
                        .foregroundColor(.btTeal)
                        .cornerRadius(15)
                }
                .padding(.top, 40)
                
                List {
                    Section("Account") {
                        NavigationLink(destination: Text("Edit Profile")) {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        NavigationLink(destination: Text("Settings")) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                    
                    Section("Actions") {
                        Button(action: {
                            // Logout Logic
                            userSession.isLoggedIn = false
                            userSession.isOnboardingComplete = false
                            userSession.currentOnboardingStep = .landing
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("My Profile")
        }
    }
}

#Preview {
    ProfileMainView()
        .environmentObject(UserSessionViewModel())
}
