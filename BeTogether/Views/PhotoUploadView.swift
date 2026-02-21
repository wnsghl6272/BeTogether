import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    @State private var photo1: UIImage? = nil
    @State private var photo2: UIImage? = nil
    
    @State private var showPhotoPicker1 = false
    @State private var showPhotoPicker2 = false
    
    // Mock image selection
    func loadMockImage(for slot: Int) {
        // In a real app, we'd use PHPickerViewController
        // Here we just use a system image or a color placeholder to represent an uploaded photo
        let mockImage = UIImage(systemName: "person.crop.square.fill")?.withTintColor(.systemTeal, renderingMode: .alwaysOriginal)
        
        if slot == 1 {
            photo1 = mockImage
        } else {
            photo2 = mockImage
        }
    }
    
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
                    Button(action: {
                        loadMockImage(for: 1)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            if let image = photo1 {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                                    .foregroundColor(.btTeal)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 140, height: 180)
                    }
                    
                    // Slot 2
                    Button(action: {
                        loadMockImage(for: 2)
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            if let image = photo2 {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                                    .foregroundColor(.btTeal)
                            } else {
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 140, height: 180)
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
                
                // Submit Button
                BTButton(title: "Submit for Review", action: {
                    router.finishOnboarding(userSession: userSession)
                }, isDisabled: photo1 == nil || photo2 == nil)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    PhotoUploadView()
        .environmentObject(UserSessionViewModel())
}
