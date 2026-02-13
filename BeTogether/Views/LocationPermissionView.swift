import SwiftUI

struct LocationPermissionView: View {
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
                    BTButton(title: "Allow Location Access") {
                        // In a real app, request permission here
                        // LocationManager.requestWhenInUseAuthorization...
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
    LocationPermissionView()
        .environmentObject(UserSessionViewModel())
}
