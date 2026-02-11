import SwiftUI

struct PhotoCardView: View {
    let user: User
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            GeometryReader { geometry in
                Image(user.imageName) // Using Asset Name
                    .resizable()
                    .aspectRatio(contentMode: .fill) // Fill the frame
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .cornerRadius(20)
            
            // Gradient Overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(20)
            
            // Info Content
            VStack(alignment: .leading, spacing: 6) {
                // Online Status Badge
                if user.isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                }
                
                // Name and Age
                HStack(alignment: .firstTextBaseline) {
                    Text(user.name)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("\(user.age)")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.btTeal)
                            .font(.system(size: 18))
                    }
                }
                
                // Region and Distance
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(user.region) • \(user.distance)km away")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // MBTI Tag
                Text(user.mbti)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.btTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(15)
                    .padding(.top, 4)
                
                // Action Buttons
                HStack(spacing: 20) {
                    // Pass Button (X)
                    Button(action: {}) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(Color.gray.opacity(0.4))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                    }
                    
                    // Add Friend Button (Main)
                    Button(action: {}) {
                        Text("Add Friend")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.btTeal)
                            .cornerRadius(27.5)
                            .shadow(color: .btTeal.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    
                    // Spark Button (Like)
                    Button(action: {}) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 55, height: 55)
                            .background(LinearGradient(gradient: Gradient(colors: [.pink, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Circle())
                            .shadow(color: .pink.opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                }
                .padding(.top, 15)
            }
            .padding(20)
            .padding(.bottom, 10)
        }
        .frame(height: 580) // Taller card for full screen feel
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    PhotoCardView(user: User.mockUsers[0])
        .padding()
        .background(Color.btIvory)
}
