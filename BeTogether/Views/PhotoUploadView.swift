import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    @State private var photo1: UIImage? = nil
    @State private var photo2: UIImage? = nil
    
    @State private var selectedItem1: PhotosPickerItem? = nil
    @State private var selectedItem2: PhotosPickerItem? = nil
    
    @State private var isSaving: Bool = false
    @State private var alertMessage: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("Profile Photos")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    Text("Upload 2 clear photos of yourself.")
                        .font(.btSubheader)
                        .foregroundColor(.gray)
                }
                .padding(.top, 50)
                
                // Photo Slots
                HStack(spacing: 20) {
                    // Slot 1
                    PhotosPicker(selection: $selectedItem1, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            if let image = photo1 {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 140, height: 180)
                    }
                    .onChange(of: selectedItem1) { _, newItem in
                        processImageSelection(newItem, slot: 1)
                    }
                    
                    // Slot 2
                    PhotosPicker(selection: $selectedItem2, matching: .images, photoLibrary: .shared()) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            if let image = photo2 {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 140, height: 180)
                    }
                    .onChange(of: selectedItem2) { _, newItem in
                        processImageSelection(newItem, slot: 2)
                    }
                }
                
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
                BTButton(title: "Submit for Review", action: {
                    submitPhotos()
                }, isDisabled: photo1 == nil || photo2 == nil || isSaving)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Photo Required"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("OK")))
        }
    }
    
    private func processImageSelection(_ item: PhotosPickerItem?, slot: Int) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                
                let hasFace = await VisionManager.shared.detectSingleFace(in: image)
                await MainActor.run {
                    if hasFace {
                        if slot == 1 { photo1 = image } else { photo2 = image }
                    } else {
                        alertMessage = "We couldn't detect exactly one clear face. Please try another photo."
                        showAlert = true
                        if slot == 1 { selectedItem1 = nil } else { selectedItem2 = nil }
                    }
                }
            }
        }
    }
    
    private func submitPhotos() {
        isSaving = true
        Task {
            do {
                // Here we would upload photos to Supabase Storage
                // let url1 = try await AuthManager.shared.uploadPhoto(photo1!)
                // let url2 = try await AuthManager.shared.uploadPhoto(photo2!)
                // then append URLs to profile data
                
                try await AuthManager.shared.updateProfile(data: [
                    "status": "pending_approval",
                    "onboarding_step": ""
                ])
                await MainActor.run {
                    isSaving = false
                    router.finishOnboarding(userSession: userSession)
                }
            } catch {
                print("Error submitting for review: \(error)")
                await MainActor.run {
                    isSaving = false
                    router.finishOnboarding(userSession: userSession)
                }
            }
        }
    }
}

#Preview {
    PhotoUploadView()
        .environmentObject(UserSessionViewModel())
}
