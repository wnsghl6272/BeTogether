import SwiftUI

/// Reusable circular avatar component that loads profile images from URL or local assets.
struct ProfileAvatarView: View {
    let imageUrl: String
    var size: CGFloat = 80
    
    var body: some View {
        Group {
            if imageUrl.hasPrefix("http") {
                SimulatorSafeAsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(ProgressView())
                        .frame(width: size, height: size)
                } errorView: { _ in
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .frame(width: size, height: size)
                }
            } else {
                Image(imageUrl)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            }
        }
        .clipShape(Circle())
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
