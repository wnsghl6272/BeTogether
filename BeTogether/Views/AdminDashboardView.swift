import SwiftUI

struct AdminDashboardView: View {
    @State private var pendingUsers: [AuthManager.PendingUserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.btIvory.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView("Loading Pending Users...")
                } else if pendingUsers.isEmpty {
                    Text("No users waiting for approval.")
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(pendingUsers, id: \.id) { user in
                                AdminUserCardView(user: user, onActionComplete: {
                                    // Remove from list
                                    if let idx = pendingUsers.firstIndex(where: { $0.id == user.id }) {
                                        pendingUsers.remove(at: idx)
                                    }
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadPendingUsers()
            }
            .refreshable {
                await loadPendingUsers()
            }
        }
    }
    
    private func loadPendingUsers() async {
        isLoading = true
        do {
            let users = try await AuthManager.shared.fetchPendingUsers()
            await MainActor.run {
                self.pendingUsers = users
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct AdminUserCardView: View {
    let user: AuthManager.PendingUserProfile
    let onActionComplete: () -> Void
    
    @State private var photos: [UIImage] = []
    @State private var isLoadingPhotos = false
    @State private var isProcessing = false
    @State private var currentPhotoIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(user.nickname ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.black)
                    Text(user.phone ?? "No Phone")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Pending")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(5)
            }
            
            // Photo Gallery
            if isLoadingPhotos {
                ProgressView("Loading photos...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if photos.isEmpty {
                Text("No Photos Available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                VStack(spacing: 6) {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(photos.indices, id: \.self) { index in
                            Image(uiImage: photos[index])
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 280)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 280)
                    
                    // Page indicator
                    HStack(spacing: 6) {
                        ForEach(photos.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentPhotoIndex ? Color.btTeal : Color.gray.opacity(0.3))
                                .frame(width: 7, height: 7)
                        }
                    }
                    
                    Text("\(currentPhotoIndex + 1) / \(photos.count)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons
            HStack(spacing: 15) {
                Button(action: {
                    Task { await rejectUser() }
                }) {
                    Text("Reject")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .disabled(isProcessing)
                
                Button(action: {
                    Task { await approveUser() }
                }) {
                    Text("Approve")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.btTeal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isProcessing)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .task {
            await loadPhotos()
        }
    }
    
    private func loadPhotos() async {
        isLoadingPhotos = true
        do {
            let photoRecords = try await AuthManager.shared.fetchUserPhotos(userId: user.id)
            var loadedImages: [UIImage] = []
            
            for record in photoRecords.sorted(by: { $0.sort_order < $1.sort_order }) {
                do {
                    let data = try await AuthManager.shared.downloadStoragePhoto(imageUrl: record.image_url)
                    if let img = UIImage(data: data) {
                        loadedImages.append(img)
                    } else {
                        print("⚠️ Could not create UIImage from data for: \(record.image_url)")
                    }
                } catch {
                    print("⚠️ Failed to download photo via storage SDK: \(error)")
                }
            }
            
            await MainActor.run {
                self.photos = loadedImages
                isLoadingPhotos = false
            }
        } catch {
            print("❌ Failed to fetch photo records for user \(user.id): \(error)")
            await MainActor.run { isLoadingPhotos = false }
        }
    }
    
    private func approveUser() async {
        isProcessing = true
        do {
            try await AuthManager.shared.approveUser(userId: user.id)
            await MainActor.run { onActionComplete() }
        } catch {
            print("Failed to approve user: \(error)")
            isProcessing = false
        }
    }
    
    private func rejectUser() async {
        isProcessing = true
        do {
            try await AuthManager.shared.rejectUser(userId: user.id)
            await MainActor.run { onActionComplete() }
        } catch {
            print("Failed to reject user: \(error)")
            isProcessing = false
        }
    }
}

#Preview {
    AdminDashboardView()
}
