import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    
    let profile: ProfileData
    let onSave: (ProfileData) -> Void
    
    @State private var fullName: String = ""
    @State private var nickname: String = ""
    @State private var occupation: String = ""
    @State private var occupationSearch: String = ""
    @State private var height: String = ""
    @State private var oneLineIntro: String = ""
    @State private var selfIntro: String = ""
    
    // Lifestyle (loaded from user_traits.lifestyle JSONB)
    @State private var lifestyleSelections: [String: String] = [:]
    @State private var isLoadingLifestyle = true
    
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOccupationPicker = false
    
    // Occupation list for searchable picker
    let occupationList = [
        "Accountant", "Actor", "Architect", "Artist", "Baker", "Banker", "Barista",
        "Business Analyst", "Business Owner", "Chef", "Civil Servant", "Coach",
        "Consultant", "Content Creator", "Counselor", "Data Analyst", "Data Scientist",
        "Dentist", "Designer", "Developer", "Doctor", "Editor", "Electrician",
        "Engineer", "Entrepreneur", "Event Planner", "Fashion Designer", "Film Director",
        "Financial Advisor", "Firefighter", "Fitness Trainer", "Flight Attendant",
        "Florist", "Freelancer", "Graphic Designer", "Hair Stylist", "Healthcare Worker",
        "Illustrator", "Influencer", "Interior Designer", "Journalist", "Lawyer",
        "Librarian", "Makeup Artist", "Manager", "Marketer", "Mechanic", "Model",
        "Musician", "Nurse", "Nutritionist", "Paramedic", "Pharmacist",
        "Photographer", "Pilot", "Police Officer", "Producer", "Professor",
        "Programmer", "Project Manager", "Psychologist", "Public Relations",
        "Real Estate Agent", "Researcher", "Sales Manager", "Scientist",
        "Social Worker", "Software Engineer", "Streamer", "Student", "Surgeon",
        "Teacher", "Translator", "Tutor", "UX Designer", "Veterinarian",
        "Videographer", "Volunteer", "Waiter", "Writer", "YouTuber", "Other"
    ]
    
    var filteredOccupations: [String] {
        if occupationSearch.isEmpty { return occupationList }
        return occupationList.filter { $0.localizedCaseInsensitiveContains(occupationSearch) }
    }
    
    let lifestyleCategories: [(String, [String])] = [
        ("Zodiac Sign", ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]),
        ("Education", ["High School", "In College", "Undergraduate", "Postgraduate"]),
        ("Family Plans", ["Want children", "Don't want children", "Not sure yet"]),
        ("Communication Style", ["Constant texter", "Video chatter", "Bad texter", "Call me"]),
        ("Love Language", ["Words of Affirmation", "Quality Time", "Receiving Gifts", "Acts of Service", "Physical Touch"]),
        ("Pets", ["Dog lover", "Cat lover", "All pets", "No pets"]),
        ("Drinking", ["Non-drinker", "Socially", "Reviewer"]),
        ("Smoking", ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]),
        ("Workout", ["Everyday", "Often", "Sometimes", "Never"])
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    HStack {
                        Label("Full Name", systemImage: "person.text.rectangle")
                        Spacer()
                        TextField("Full Name", text: $fullName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.btTeal)
                    }
                    
                    HStack {
                        Label("Nickname (ID)", systemImage: "tag")
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
                        Button(action: { showOccupationPicker = true }) {
                            Text(occupation.isEmpty ? "Select" : occupation)
                                .foregroundColor(occupation.isEmpty ? .secondary : .btTeal)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Label("Height (cm)", systemImage: "ruler")
                        Spacer()
                        TextField("Height", text: $height)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.btTeal)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Lifestyle & Preferences") {
                    if isLoadingLifestyle {
                        HStack {
                            Spacer()
                            ProgressView("Loading lifestyle...")
                            Spacer()
                        }
                    } else {
                        ForEach(lifestyleCategories, id: \.0) { category in
                            Picker(selection: Binding(
                                get: { lifestyleSelections[category.0] ?? "" },
                                set: { lifestyleSelections[category.0] = $0.isEmpty ? nil : $0 }
                            )) {
                                Text("Not set").tag("")
                                ForEach(category.1, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            } label: {
                                Label(category.0, systemImage: iconForCategory(category.0))
                            }
                        }
                    }
                }
                
                Section("Introduction") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("One-line Intro")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(oneLineIntro.count)/80")
                                .font(.caption2)
                                .foregroundColor(oneLineIntro.count >= 70 ? .orange : .gray)
                        }
                        TextField("Show off your charm in one sentence!", text: $oneLineIntro)
                            .onChange(of: oneLineIntro) { _, newValue in
                                if newValue.count > 80 {
                                    oneLineIntro = String(newValue.prefix(80))
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("About Me")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(selfIntro.count)/500")
                                .font(.caption2)
                                .foregroundColor(selfIntro.count >= 450 ? .orange : .gray)
                        }
                        
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.btTeal)
                                .font(.caption2)
                            Text("AI uses this to find your perfect match!")
                                .font(.caption2)
                                .foregroundColor(.btTeal)
                        }
                        
                        TextEditor(text: $selfIntro)
                            .frame(minHeight: 100)
                            .onChange(of: selfIntro) { _, newValue in
                                if newValue.count > 500 {
                                    selfIntro = String(newValue.prefix(500))
                                }
                            }
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
                fullName = profile.full_name ?? ""
                nickname = profile.nickname ?? ""
                occupation = profile.occupation ?? ""
                occupationSearch = profile.occupation ?? ""
                height = profile.height ?? ""
                oneLineIntro = profile.one_line_intro ?? ""
                selfIntro = profile.self_intro ?? ""
                loadLifestyleData()
            }
            .sheet(isPresented: $showOccupationPicker) {
                OccupationPickerSheet(
                    occupationList: occupationList,
                    selectedOccupation: $occupation,
                    occupationSearch: $occupationSearch
                )
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Zodiac Sign": return "sparkles"
        case "Education": return "graduationcap"
        case "Family Plans": return "person.3.fill"
        case "Communication Style": return "message"
        case "Love Language": return "heart"
        case "Pets": return "pawprint"
        case "Drinking": return "wineglass"
        case "Smoking": return "smoke"
        case "Workout": return "figure.run"
        default: return "circle"
        }
    }
    
    private func loadLifestyleData() {
        Task {
            guard let userId = AuthManager.shared.currentUserId else {
                await MainActor.run { isLoadingLifestyle = false }
                return
            }
            
            do {
                struct TraitResult: Decodable { let lifestyle: [String: String]? }
                let traits: [TraitResult] = try await AuthManager.shared.client.from("user_traits")
                    .select("lifestyle")
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if let lifestyle = traits.first?.lifestyle {
                    await MainActor.run {
                        lifestyleSelections = lifestyle
                    }
                }
            } catch {
                print("Failed to load lifestyle: \(error)")
            }
            
            await MainActor.run { isLoadingLifestyle = false }
        }
    }
    
    private func saveChanges() {
        isSaving = true
        Task {
            do {
                let profileData: [String: Any] = [
                    "full_name": fullName,
                    "occupation": occupation,
                    "height": height,
                    "one_line_intro": oneLineIntro,
                    "self_intro": selfIntro
                ]
                
                try await AuthManager.shared.updateProfile(data: profileData)
                
                // Save lifestyle to user_traits
                try await AuthManager.shared.updateUserTraits(data: ["lifestyle": lifestyleSelections])
                
                await MainActor.run {
                    var updated = profile
                    updated.full_name = fullName
                    updated.nickname = nickname
                    updated.occupation = occupation
                    updated.height = height
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
