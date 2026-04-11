import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    
    let profile: ProfileData
    let onSave: (ProfileData) -> Void
    
    @State private var nickname: String = ""
    @State private var occupation: String = ""
    @State private var height: String = ""
    @State private var university: String = ""
    @State private var drinking: String = ""
    @State private var smoking: String = ""
    @State private var oneLineIntro: String = ""
    @State private var selfIntro: String = ""
    
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let drinkingOptions = ["Not at all", "Socially", "Often", "Regularly"]
    let smokingOptions = ["Non-smoker", "Sometimes", "Daily"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    HStack {
                        Label("Nickname", systemImage: "person")
                        Spacer()
                        HStack(spacing: 4) {
                            Text(profile.nickname ?? "")
                                .foregroundColor(.secondary)
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Label("Occupation", systemImage: "briefcase")
                        Spacer()
                        TextField("Occupation", text: $occupation)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.btTeal)
                    }
                    
                    HStack {
                        Label("Height (cm)", systemImage: "ruler")
                        Spacer()
                        TextField("Height", text: $height)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.btTeal)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Label("University", systemImage: "building.columns")
                        Spacer()
                        TextField("University", text: $university)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.btTeal)
                    }
                }
                
                Section("Lifestyle") {
                    Picker(selection: $drinking) {
                        Text("Not set").tag("")
                        ForEach(drinkingOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    } label: {
                        Label("Drinking", systemImage: "wineglass")
                    }
                    
                    Picker(selection: $smoking) {
                        Text("Not set").tag("")
                        ForEach(smokingOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    } label: {
                        Label("Smoking", systemImage: "smoke")
                    }
                }
                
                Section("Introduction") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One-line Intro")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("A short intro about you...", text: $oneLineIntro)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Me")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $selfIntro)
                            .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.btTeal)
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView("Saving...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                        )
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                nickname = profile.nickname ?? ""
                occupation = profile.occupation ?? ""
                height = profile.height ?? ""
                university = profile.university ?? ""
                drinking = profile.drinking ?? ""
                smoking = profile.smoking ?? ""
                oneLineIntro = profile.one_line_intro ?? ""
                selfIntro = profile.self_intro ?? ""
            }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let data: [String: Any] = [
                    "occupation": occupation,
                    "height": height,
                    "university": university,
                    "drinking": drinking,
                    "smoking": smoking,
                    "one_line_intro": oneLineIntro,
                    "self_intro": selfIntro
                ]
                
                try await AuthManager.shared.updateProfile(data: data)
                
                await MainActor.run {
                    var updated = profile
                    updated.nickname = nickname
                    updated.occupation = occupation
                    updated.height = height
                    updated.university = university
                    updated.drinking = drinking
                    updated.smoking = smoking
                    updated.one_line_intro = oneLineIntro
                    updated.self_intro = selfIntro
                    
                    isSaving = false
                    onSave(updated)
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}
