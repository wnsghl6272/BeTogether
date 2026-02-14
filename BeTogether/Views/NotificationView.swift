import SwiftUI

struct NotificationView: View {
    let notifications = [
        NotificationItem(type: .friendRequest, user: "Alice", time: "2m ago"),
        NotificationItem(type: .sparkReceived, user: "Bob", time: "1h ago"),
        NotificationItem(type: .profileView, user: "Charlie", time: "3h ago"),
        NotificationItem(type: .friendRequest, user: "David", time: "Yesterday"),
        NotificationItem(type: .sparkReceived, user: "Eve", time: "2 days ago")
    ]
    
    var body: some View {
        NavigationView {
            List(notifications) { item in
                HStack(spacing: 15) {
                    // Icon based on type
                    ZStack {
                        Circle()
                            .fill(item.type.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: item.type.icon)
                            .foregroundColor(item.type.color)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Message construction
                        Text(item.message)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text(item.time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Action Button (if relevant)
                    if item.type == .friendRequest {
                        Button("Accept") {
                            // Action
                        }
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.btTeal)
                        .cornerRadius(15)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
        }
    }
}

// MARK: - Models

struct NotificationItem: Identifiable {
    let id = UUID()
    let type: NotificationType
    let user: String
    let time: String
    
    var message: String {
        switch type {
        case .friendRequest: return "\(user) sent you a friend request."
        case .sparkReceived: return "\(user) sent you a Spark!"
        case .profileView: return "\(user) viewed your profile."
        }
    }
}

enum NotificationType {
    case friendRequest
    case sparkReceived
    case profileView
    
    var icon: String {
        switch self {
        case .friendRequest: return "person.badge.plus.fill"
        case .sparkReceived: return "sparkles"
        case .profileView: return "eye.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .friendRequest: return .blue
        case .sparkReceived: return .yellow
        case .profileView: return .purple
        }
    }
}

#Preview {
    NotificationView()
}
