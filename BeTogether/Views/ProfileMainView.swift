import SwiftUI

struct ProfileMainView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    @State private var profile: ProfileData? = nil
    @State private var photos: [AuthManager.UserPhotoRecord] = []
    @State private var lifestyleData: [String: String] = [:]
    @State private var isLoading = true
    @State private var isEditing = false
    @State private var showBlockedContacts = false
    @State private var showTakeBreakAlert = false
    @State private var showDeleteAlert = false
    @State private var isBreakActive = false
    @State private var showReportSheet = false
    @State private var showPhotoEdit = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let profile = profile {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Photo Gallery
                            photoGallerySection
                            
                            // Basic Info
                            profileHeaderSection(profile)
                            
                            // Attendance Streak
                            attendanceStreakSection
                            
                            // Details
                            profileDetailsSection(profile)
                            
                            // Settings
                            settingsSection
                            
                            // Account Actions
                            accountActionsSection
                        }
                        .padding(.bottom, 30)
                    }
                } else {
                    Text("Unable to load profile.")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Done" : "Edit") {
                        if isEditing {
                            saveProfile()
                        }
                        isEditing.toggle()
                    }
                    .foregroundColor(.btTeal)
                }
            }
            .sheet(isPresented: $isEditing) {
                if let profile = profile {
                    ProfileEditView(profile: profile) { updatedProfile in
                        self.profile = updatedProfile
                        isEditing = false
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                ReportSubmissionView()
            }
            .sheet(isPresented: $showPhotoEdit) {
                ProfilePhotoEditView {
                    loadProfileData()
                }
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    // MARK: - Photo Gallery
    private var photoGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !photos.isEmpty {
                TabView {
                    ForEach(photos, id: \.sort_order) { photo in
                        GeometryReader { geometry in
                            SimulatorSafeAsyncImage(url: URL(string: photo.image_url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: max(0, geometry.size.width), height: max(0, geometry.size.height))
                                    .clipped()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(ProgressView())
                            } errorView: { _ in
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                            .font(.largeTitle)
                                    )
                            }
                        }
                    }
                }
                .frame(height: 400)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray5))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No photos uploaded")
                                .foregroundColor(.gray)
                        }
                    )
                    .padding(.horizontal)
            }
            
            // Edit Photos Button
            Button(action: { showPhotoEdit = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Manage Photos")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.btTeal)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Profile Header
    private func profileHeaderSection(_ profile: ProfileData) -> some View {
        VStack(spacing: 8) {
            Text(profile.full_name ?? profile.nickname ?? "Unknown")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                if let mbti = profile.mbti, !mbti.isEmpty {
                    Label(mbti, systemImage: "brain.head.profile")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.btTeal.opacity(0.1))
                        .foregroundColor(.btTeal)
                        .cornerRadius(15)
                }
                
                if let age = profile.age {
                    Label("\(age)", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let intro = profile.one_line_intro, !intro.isEmpty {
                Text("\"" + intro + "\"")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Attendance Streak
    private var attendanceStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Check-In Streak")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 8) {
                let days = StoreManager.shared.economy?.attendanceDays ?? 0
                ForEach(1...7, id: \.self) { day in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(day <= days ? Color.btTeal : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            if day <= days {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.caption.bold())
                            } else {
                                // Show upcoming rewards
                                if day == 3 || day == 5 {
                                    Image(systemName: "gift.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                } else if day == 7 {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                        }
                        Text("Day \(day)")
                            .font(.caption2)
                            .foregroundColor(day <= days ? .btTeal : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
    
    // MARK: - Profile Details
    private func profileDetailsSection(_ profile: ProfileData) -> some View {
        VStack(spacing: 0) {
            ProfileDetailRow(icon: "phone.fill", title: "Phone", value: profile.phone ?? "Not set")
            ProfileDetailRow(icon: "tag", title: "Nickname (Private ID)", value: profile.nickname ?? "Not set")
            ProfileDetailRow(icon: "briefcase", title: "Occupation", value: profile.occupation ?? "Not set")
            ProfileDetailRow(icon: "ruler", title: "Height", value: profile.height ?? "Not set")
            ProfileDetailRow(icon: "building.columns", title: "University", value: profile.university ?? "Not set")
            ProfileDetailRow(icon: "person.text.rectangle", title: "Gender", value: profile.gender ?? "Not set")
            
            // Lifestyle data from user_traits
            if !lifestyleData.isEmpty {
                Divider().padding(.leading, 50)
                ForEach(lifestyleData.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    ProfileDetailRow(icon: iconForLifestyle(key), title: key, value: value)
                }
            }
            
            if let selfIntro = profile.self_intro, !selfIntro.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("About Me", systemImage: "text.quote")
                        .font(.subheadline.bold())
                        .foregroundColor(.btTeal)
                    
                    Text(selfIntro)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
    
    private func iconForLifestyle(_ key: String) -> String {
        switch key {
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
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: BlockedContactsManagerView()) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    
                    Text("Blocked Contacts")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
            
            Divider().padding(.leading, 50)
            
            Button(action: { showReportSheet = true }) {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .foregroundColor(.btTeal)
                        .frame(width: 28)
                    
                    Text("Help & Report Issue")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
    }
    
    // MARK: - Account Actions
    private var accountActionsSection: some View {
        VStack(spacing: 0) {
            // Take a Break
            Button(action: { showTakeBreakAlert = true }) {
                HStack {
                    Image(systemName: isBreakActive ? "play.circle.fill" : "moon.fill")
                        .foregroundColor(.orange)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isBreakActive ? "Resume Account" : "Take a Break")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(isBreakActive ? "Your profile is currently hidden" : "Temporarily hide your profile")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isBreakActive {
                        Text("PAUSED")
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
            
            Divider().padding(.leading, 50)
            
            // Delete Account
            Button(action: { showDeleteAlert = true }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Text("Permanently delete all your data")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
            
            Divider().padding(.leading, 50)
            
            // Logout
            Button(action: { performLogout() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.gray)
                        .frame(width: 28)
                    
                    Text("Logout")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
        .alert("Take a Break", isPresented: $showTakeBreakAlert) {
            Button("Cancel", role: .cancel) {}
            Button(isBreakActive ? "Resume" : "Pause", role: isBreakActive ? .none : .destructive) {
                toggleBreak()
            }
        } message: {
            Text(isBreakActive
                 ? "Resume your account? Your profile will be visible again."
                 : "Your profile will be hidden from matches and recommendations. You can resume anytime.")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action is irreversible. All your data, matches, messages, and photos will be permanently deleted.")
        }
    }
    
    private func performLogout() {
        Task {
            do {
                try await AuthManager.shared.signOut()
            } catch {
                print("Error signing out: \(error)")
            }
            await MainActor.run {
                userSession.isLoggedIn = false
                userSession.isOnboardingComplete = false
                userSession.currentOnboardingStep = .landing
                router.authState = .unauthenticated
            }
        }
    }
    
    private func toggleBreak() {
        Task {
            let newStatus = isBreakActive ? "approved" : "paused"
            do {
                try await AuthManager.shared.updateProfile(data: ["status": newStatus])
                await MainActor.run {
                    isBreakActive = !isBreakActive
                }
            } catch {
                print("Error toggling break: \(error)")
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            do {
                // Mark profile for deletion - set status to 'deleted'
                try await AuthManager.shared.updateProfile(data: ["status": "deleted"])
                try await AuthManager.shared.signOut()
                await MainActor.run {
                    userSession.isLoggedIn = false
                    userSession.isOnboardingComplete = false
                    userSession.currentOnboardingStep = .landing
                    router.authState = .unauthenticated
                }
            } catch {
                print("Error deleting account: \(error)")
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadProfileData() {
        Task {
            guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
                  let userId = AuthManager.shared.currentUserId else {
                await MainActor.run { isLoading = false }
                return
            }
            
            do {
                let client = AuthManager.shared.client
                
                // Fetch profile
                let profileResult: [ProfileData] = try await client.from("profiles")
                    .select("id, phone, full_name, nickname, birth_date, occupation, height, university, gender, one_line_intro, self_intro, status")
                    .eq("id", value: userId)
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                    .value
                
                // Fetch MBTI and lifestyle from user_traits
                struct TraitResult: Decodable { let mbti: String?; let lifestyle: [String: String]? }
                let traits: [TraitResult] = (try? await client.from("user_traits")
                    .select("mbti, lifestyle")
                    .eq("user_id", value: userId)
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                    .value) ?? []
                
                // Fetch photos
                let userPhotos = try await AuthManager.shared.fetchUserPhotos(userId: userId)
                
                await MainActor.run {
                    var profileData = profileResult.first
                    profileData?.mbti = traits.first?.mbti
                    
                    // Calculate age
                    if let birthDate = profileData?.birth_date {
                        let birthYearString = String(birthDate.prefix(4))
                        if let birthYear = Int(birthYearString) {
                            let currentYear = Calendar.current.component(.year, from: Date())
                            profileData?.age = currentYear - birthYear
                        }
                    }
                    
                    self.profile = profileData
                    self.photos = userPhotos
                    self.lifestyleData = traits.first?.lifestyle ?? [:]
                    self.isBreakActive = (profileData?.status == "paused")
                    self.isLoading = false
                }
            } catch {
                print("Failed to load profile: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func saveProfile() {
        // Handled by ProfileEditView's onSave callback
    }
}

// MARK: - Supporting Types

struct ProfileData: Decodable {
    let id: String
    var full_name: String?
    var nickname: String?
    let birth_date: String?
    var occupation: String?
    var height: String?
    var university: String?
    var gender: String?
    var one_line_intro: String?
    var self_intro: String?
    var mbti: String?
    var age: Int?
    var status: String?
    var phone: String?
    
    enum CodingKeys: String, CodingKey {
        case id, phone, full_name, nickname, birth_date, occupation, height, university
        case gender, one_line_intro, self_intro, status
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        full_name = try c.decodeIfPresent(String.self, forKey: .full_name)
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        birth_date = try c.decodeIfPresent(String.self, forKey: .birth_date)
        occupation = try c.decodeIfPresent(String.self, forKey: .occupation)
        height = try c.decodeIfPresent(String.self, forKey: .height)
        university = try c.decodeIfPresent(String.self, forKey: .university)
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        one_line_intro = try c.decodeIfPresent(String.self, forKey: .one_line_intro)
        self_intro = try c.decodeIfPresent(String.self, forKey: .self_intro)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        mbti = nil
        age = nil
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.btTeal)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(value == "Not set" ? .gray : .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        
        Divider().padding(.leading, 56)
    }
}

#Preview {
    ProfileMainView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(OnboardingRouter())
}
import SwiftUI

struct ReportSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Optional target user to report
    var targetUserId: String?
    var targetUserName: String?
    
    @State private var selectedReason: String = "Inappropriate Behavior"
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    
    var reasons: [String] {
        if targetUserId != nil {
            return [
                "Inappropriate Behavior",
                "Spam or Scam",
                "Fake Profile",
                "Harassment or Bullying",
                "Other"
            ]
        } else {
            return [
                "App Bug / Issue",
                "Other"
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let targetName = targetUserName {
                    Section(header: Text("Reporting User")) {
                        Text(targetName)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Reason")) {
                    Picker("Select Reason", selection: $selectedReason) {
                        ForEach(reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Details")) {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                        .overlay(
                            Group {
                                if details.isEmpty {
                                    Text("Please provide more details about your report...")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit")
                                .bold()
                        }
                    }
                    .disabled(isSubmitting || details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if selectedReason == "Inappropriate Behavior" && targetUserId == nil {
                    selectedReason = "App Bug / Issue"
                }
            }
            .navigationTitle(targetUserId != nil ? "Report User" : "Report Issue")
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your report. Our team will review it shortly.")
            }
        }
    }
    
    private func submitReport() {
        guard !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
                      let reporterId = AuthManager.shared.currentUserId else {
                    await MainActor.run {
                        self.errorMessage = "You must be logged in to submit a report."
                        self.isSubmitting = false
                    }
                    return
                }
                
                let client = AuthManager.shared.client
                
                struct ReportInsert: Encodable {
                    let reporter_id: String
                    let target_id: String?
                    let reason: String
                    let details: String
                }
                
                let reportData = ReportInsert(
                    reporter_id: reporterId,
                    target_id: targetUserId,
                    reason: selectedReason,
                    details: details
                )
                
                try await client.from("reports")
                    .insert(reportData)
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                
                await MainActor.run {
                    self.isSubmitting = false
                    self.showSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "Failed to submit report. Please try again."
                }
                print("Report error: \(error)")
            }
        }
    }
}
