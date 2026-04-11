import SwiftUI
import Supabase

struct DBNotification: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let actorId: UUID
    let type: String
    let message: String?
    let isRead: Bool
    var isSeen: Bool?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case type
        case message
        case isRead = "is_read"
        case isSeen = "is_seen"
        case createdAt = "created_at"
    }
}

@MainActor
class NotificationCenterViewModel: ObservableObject {
    @Published var notifications: [DBNotification] = []
    @Published var isLoading = false
    
    func fetchNotifications(userId: String) async {
        self.isLoading = true
        do {
            let fetched: [DBNotification] = try await AuthManager.shared.client
                .from("notifications")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
                
                self.notifications = fetched
                self.isLoading = false
            
            // Mark as seen immediately on fetch
            let unseenIds = fetched.filter { !($0.isSeen ?? false) }.map { $0.id }
            if !unseenIds.isEmpty {
                _ = try await AuthManager.shared.client
                    .from("notifications")
                    .update(["is_seen": true])
                    .in("id", values: unseenIds)
                    .execute()
                
                await MainActor.run {
                    NotificationManager.shared.resetUnread()
                }
            }
        } catch {
            print("Failed to fetch notifications: \(error)")
            self.isLoading = false
        }
    }
    
    func deleteNotification(id: UUID) {
        Task {
            do {
                try await AuthManager.shared.client
                    .from("notifications")
                    .delete()
                    .eq("id", value: id)
                    .execute()
                
                self.notifications.removeAll { $0.id == id }
            } catch {
                print("Failed to delete notification: \(error)")
            }
        }
    }
}

struct NotificationView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()
    @EnvironmentObject var userSession: UserSessionViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading notifications...")
            } else if viewModel.notifications.isEmpty {
                Text("No notifications yet.")
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.notifications) { item in
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(getColor(for: item.type).opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: getIcon(for: item.type))
                                    .foregroundColor(getColor(for: item.type))
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.message ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Text(item.createdAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .opacity((item.isSeen ?? false) ? 0.6 : 1.0)
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let userId = AuthManager.shared.currentUserId {
                Task {
                    await viewModel.fetchNotifications(userId: userId)
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let notification = viewModel.notifications[index]
            viewModel.deleteNotification(id: notification.id)
        }
    }
    
    private func getIcon(for type: String) -> String {
        switch type {
        case "like": return "heart.fill"
        case "message": return "message.fill"
        default: return "bell.fill"
        }
    }
    
    private func getColor(for type: String) -> Color {
        switch type {
        case "like": return .pink
        case "message": return .btTeal
        default: return .blue
        }
    }
}

#Preview {
    NavigationView {
        NotificationView()
            .environmentObject(UserSessionViewModel())
    }
}
