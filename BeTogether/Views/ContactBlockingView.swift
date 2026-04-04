import SwiftUI

struct ContactBlockingView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @State private var showingContactPicker = false
    @State private var blockedContacts: [BlockedContact] = []
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "hand.raised.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red)
                        .padding(.top, 40)
                    
                    Text("Block Contacts")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    
                    Text("Don't want to meet someone you know?\nBlock them by phone number.")
                        .font(.btSubheader)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Blocked List
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if blockedContacts.isEmpty {
                            Text("No contacts blocked yet.")
                                .font(.btBody)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                        } else {
                            ForEach(blockedContacts, id: \.id) { contact in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.btBody)
                                            .foregroundColor(.black)
                                        Text(contact.phoneNumber)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        blockedContacts.removeAll { $0.id == contact.id }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.btIvory)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 200)
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        showingContactPicker = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Load Contacts")
                        }
                        .font(.btButton)
                        .foregroundColor(.btTeal)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.btTeal, lineWidth: 1)
                        )
                    }
                    .sheet(isPresented: $showingContactPicker) {
                        ContactPicker(selectedContacts: $blockedContacts)
                    }
                    
                    Text("We securely hash phone numbers using SHA-256.\nHonsyl never stores your contacts.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 10)
                    
                    if isSaving {
                        ProgressView()
                            .padding(.bottom, 10)
                    }
                    
                    BTButton(title: "Complete & Start") {
                        isSaving = true
                        Task {
                            do {
                                let hashes = blockedContacts.map { $0.hashedNumber }.filter { !$0.isEmpty }
                                try await AuthManager.shared.saveBlockedContacts(hashes: hashes)
                                try await AuthManager.shared.updateProfile(data: ["onboarding_step": "photoUpload"])
                                await MainActor.run {
                                    isSaving = false
                                    router.navigate(to: .photoUpload)
                                }
                            } catch {
                                print("Error updating onboarding step or saving contacts: \(error)")
                                await MainActor.run {
                                    isSaving = false
                                    errorMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        }
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An unknown error occurred."), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ContactBlockingView()
        .environmentObject(UserSessionViewModel())
}
