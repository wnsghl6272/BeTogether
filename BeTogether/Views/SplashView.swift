import SwiftUI

struct SplashView: View {
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Logo Container
                VStack(spacing: 8) {
                    // Heart Icon with connection feel
                    ZStack {
                        Circle()
                            .fill(Color.btTeal)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    // Brand Name - Stacked for logo feel
                    VStack(spacing: 2) {
                        Text("Be")
                            .font(.system(size: 32, weight: .light, design: .rounded))
                            .foregroundColor(.btTeal)
                        Text("Together")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.btTeal)
                    }
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
