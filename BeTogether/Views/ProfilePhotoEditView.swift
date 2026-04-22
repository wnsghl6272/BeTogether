import SwiftUI
import PhotosUI

struct ProfilePhotoEditView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var slots: [PhotoSlot] = (0..<6).map { PhotoSlot(id: $0) }
    
    @State private var isSaving: Bool = false
    @State private var isLoadingPhotos: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    
    // Add closure to notify parent that photos were updated
    var onPhotosUpdated: () -> Void = {}
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var canSubmit: Bool {
        // Must have at least the first two photos
        return slots[0].image != nil && slots[1].image != nil
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("Manage Photos")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    Text("The first 2 photos must clearly show your face.")
                        .font(.btSubheader)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Photo Slots (3x2 Grid)
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach($slots) { $slot in
                        ZStack {
                            PhotosPicker(selection: $slot.pickerItem, matching: .images, photoLibrary: .shared()) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(slot.id < 2 ? Color.btTeal.opacity(0.1) : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(slot.id < 2 ? Color.btTeal : Color.gray.opacity(0.3), lineWidth: slot.id < 2 ? 2 : 1)
                                        )
                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    
                                    if let image = slot.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                    } else {
                                        VStack(spacing: 5) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 24, weight: slot.id < 2 ? .bold : .regular))
                                                .foregroundColor(slot.id < 2 ? .btTeal : .gray)
                                            
                                            if slot.id < 2 {
                                                Text("Required")
                                                    .font(.caption2)
                                                    .foregroundColor(.btTeal)
                                            }
                                        }
                                    }
                                }
                                .aspectRatio(3/4, contentMode: .fit)
                            }
                            .onChange(of: slot.pickerItem) { _, newItem in
                                processImageSelection(newItem, index: slot.id)
                            }
                            
                            // Delete Button (Layered above PhotosPicker to consume tap)
                            if slot.image != nil {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            // Reset the current slot
                                            slots[slot.id].image = nil
                                            slots[slot.id].pickerItem = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                                .background(Circle().fill(Color.black.opacity(0.5)))
                                        }
                                        .padding(8)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Warning
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text("Photos must clearly show your face.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                if isSaving {
                    ProgressView()
                        .padding(.bottom, 10)
                }
                
                // Submit Button
                BTButton(title: "Save Changes", action: {
                    submitPhotos()
                }, isDisabled: !canSubmit || isSaving)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            
            if isSaving || isLoadingPhotos {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                ProgressView(isSaving ? "Saving Photos..." : "Loading Your Photos...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
        .task {
            await loadExistingPhotos()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Photo Required"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Manage Photos")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func processImageSelection(_ item: PhotosPickerItem?, index: Int) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                let hasFace: Bool
                if index < 2 {
                    hasFace = await VisionManager.shared.detectSingleFace(in: image)
                } else {
                    // Only the first 2 slots require a face
                    hasFace = true
                }
                
                await MainActor.run {
                    if hasFace {
                        slots[index].image = image
                    } else {
                        alertMessage = "We couldn't detect exactly one clear face for the required photo. Please try another one."
                        showAlert = true
                        slots[index].pickerItem = nil
                    }
                }
            }
        }
    }
    
    private func submitPhotos() {
        isSaving = true
        Task {
            do {
                guard let session = try? await AuthManager.shared.client.auth.session else {
                    throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                let userId = session.user.id.uuidString.lowercased()
                
                // 0. Remove existing photos from DB to overwrite previous submission
                try await AuthManager.shared.deleteAllUserPhotos(userId: userId)
                
                // 1. Process and upload each photo
                for (index, slot) in slots.enumerated() {
                    if let image = slot.image {
                        // Compress and resize image to max 800px
                        let maxSize: CGFloat = 800.0
                        let scale = min(maxSize/image.size.width, maxSize/image.size.height)
                        let newSize = image.size.width > maxSize || image.size.height > maxSize
                                    ? CGSize(width: image.size.width * scale, height: image.size.height * scale)
                                    : image.size
                        
                        let format = UIGraphicsImageRendererFormat()
                        format.scale = 1
                        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
                        let resizedImage = renderer.image { _ in
                            image.draw(in: CGRect(origin: .zero, size: newSize))
                        }
                        
                        // Try HEIC first, fallback to JPEG
                        let imageData: Data
                        let fileExtension: String
                        let contentType: String
                        
                        if let heicData = resizedImage.heicData() {
                            imageData = heicData
                            fileExtension = "heic"
                            contentType = "image/heic"
                        } else if let jpegData = resizedImage.jpegData(compressionQuality: 0.6) {
                            imageData = jpegData
                            fileExtension = "jpg"
                            contentType = "image/jpeg"
                        } else {
                            print("Failed to compress image at slot \(index)")
                            continue
                        }
                        
                        // Upload to Storage
                        let filename = UUID().uuidString
                        let path = "\(userId)/\(filename).\(fileExtension)"
                        
                        let publicUrl = try await AuthManager.shared.uploadUserPhoto(data: imageData, path: path, contentType: contentType)
                        
                        // Insert into DB
                        try await AuthManager.shared.saveUserPhotoRecord(
                            userId: userId,
                            imageUrl: publicUrl,
                            sortOrder: index,
                            isVerified: index < 2 
                        )
                    }
                }
                
                await MainActor.run {
                    isSaving = false
                    onPhotosUpdated()
                    dismiss()
                }
            } catch {
                print("Error uploading photos: \(error)")
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Failed to upload photos. Please try again."
                    showAlert = true
                }
            }
        }
    }
    
    private func loadExistingPhotos() async {
        guard let session = try? await AuthManager.shared.client.auth.session else { return }
        let userId = session.user.id.uuidString.lowercased()
        
        await MainActor.run { isLoadingPhotos = true }
        
        do {
            let existingPhotos = try await AuthManager.shared.fetchUserPhotos(userId: userId)
            
            for photo in existingPhotos {
                if photo.sort_order >= 0 && photo.sort_order < 6, let url = URL(string: photo.image_url) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                slots[photo.sort_order].image = image
                            }
                        }
                    } catch {
                        print("Failed to download image at \(photo.image_url): \(error)")
                    }
                }
            }
        } catch {
            print("Failed to fetch existing photos records: \(error)")
        }
        
        await MainActor.run { isLoadingPhotos = false }
    }
}
