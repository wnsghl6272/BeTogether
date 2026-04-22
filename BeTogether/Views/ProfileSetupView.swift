import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    enum ProfileStep {
        case birthday
        case fullname
        case nickname
        case gender
        case occupation
        case height
        case oneLineIntro
        case selfIntro
    }
    
    @State private var curStep: ProfileStep = .birthday
    
    // Data States
    @State private var birthDate: Date = Date()
    @State private var fullName: String = ""
    @State private var nickname: String = ""
    @State private var gender: String = "" // "Male" or "Female"
    @State private var occupation: String = ""
    @State private var occupationSearch: String = ""
    @State private var height: String = ""
    @State private var oneLineIntro: String = ""
    @State private var selfIntro: String = ""
    @State private var isSaving: Bool = false
    
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
    
    // Validation
    var isAgeValid: Bool {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        return age >= 19
    }
    
    var body: some View {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                switch curStep {
                case .birthday:
                    birthdayStep
                case .fullname:
                    fullNameStep
                case .nickname:
                    nicknameStep
                case .gender:
                    genderStep
                case .occupation:
                    occupationStep
                case .height:
                    heightStep
                case .oneLineIntro:
                    oneLineIntroStep
                case .selfIntro:
                    selfIntroStep
                }
                
                Spacer()
            }
            .animation(.easeInOut, value: curStep)
        }
    }
    
    // MARK: - Steps
    
    var birthdayStep: some View {
        VStack(spacing: 30) {
            Text("When were you born?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            
            if !isAgeValid {
                Text("You must be at least 19 years old to join.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            BTButton(title: "Next", action: {
                userSession.birthDate = birthDate
                curStep = .fullname
            }, isDisabled: !isAgeValid)
            .padding(.horizontal, 40)
        }
    }
    
    
    var fullNameStep: some View {
        VStack(spacing: 30) {
            Text("What's your full name?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            Text("Your friends will see this name.")
                .font(.caption)
                .foregroundColor(.gray)

            BTTextField(placeholder: "Full Name", text: $fullName)
                .padding(.horizontal, 40)
            
            BTButton(title: "Next", action: {
                userSession.fullName = fullName
                curStep = .nickname
            }, isDisabled: fullName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 40)
        }
    }

    @State private var nicknameCheckStatus: String? = nil
    @State private var isNicknameAvailable: Bool = false
    @State private var isCheckingNickname: Bool = false
    
    var nicknameStep: some View {
        VStack(spacing: 24) {
            Text("What's your nickname?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            Text("This will be your unique ID for friend requests.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 10) {
                BTTextField(placeholder: "Nickname", text: $nickname)
                    .onChange(of: nickname) { _, _ in
                        // Reset availability when nickname changes
                        isNicknameAvailable = false
                        nicknameCheckStatus = nil
                    }
                
                Button(action: {
                    checkNicknameDuplicate()
                }) {
                    if isCheckingNickname {
                        ProgressView()
                            .frame(width: 80, height: 48)
                    } else {
                        Text("Check")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(width: 80, height: 48)
                            .background(nickname.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.btTeal)
                            .cornerRadius(12)
                    }
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty || isCheckingNickname)
            }
            .padding(.horizontal, 40)
            
            if let status = nicknameCheckStatus {
                HStack(spacing: 6) {
                    Image(systemName: isNicknameAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(status)
                }
                .font(.caption)
                .foregroundColor(isNicknameAvailable ? .green : .red)
                .animation(.easeIn, value: nicknameCheckStatus)
            }
            
            BTButton(title: "Next", action: {
                userSession.nickname = nickname
                curStep = .gender
            }, isDisabled: !isNicknameAvailable)
            .padding(.horizontal, 40)
        }
    }
    
    private func checkNicknameDuplicate() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        isCheckingNickname = true
        Task {
            do {
                let existingId = try await InteractionManager.shared.fetchUserByNickname(trimmed)
                await MainActor.run {
                    isCheckingNickname = false
                    if existingId != nil {
                        isNicknameAvailable = false
                        nicknameCheckStatus = "This nickname is already taken."
                    } else {
                        isNicknameAvailable = true
                        nicknameCheckStatus = "This nickname is available!"
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingNickname = false
                    isNicknameAvailable = false
                    nicknameCheckStatus = "Error checking nickname."
                }
            }
        }
    }
    
    var genderStep: some View {
        VStack(spacing: 30) {
            Text("What is your gender?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            HStack(spacing: 15) {
                BTSelectionButton(
                    title: "Female",
                    isSelected: gender == "Female",
                    action: { gender = "Female" }
                )
                
                BTSelectionButton(
                    title: "Male",
                    isSelected: gender == "Male",
                    action: { gender = "Male" }
                )
                
                BTSelectionButton(
                    title: "Other",
                    isSelected: gender == "Other",
                    action: { gender = "Other" }
                )
            }
            .padding(.horizontal, 40)
            
            BTButton(title: "Next", action: {
                userSession.gender = gender
                curStep = .occupation
            }, isDisabled: gender.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var occupationStep: some View {
        VStack(spacing: 20) {
            Text("What is your occupation?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            Text("Search or select from the list below.")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Type to search...", text: $occupationSearch)
                    .autocapitalization(.words)
                
                if !occupationSearch.isEmpty {
                    Button(action: { occupationSearch = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 40)
            
            // Selection indicator
            if !occupation.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.btTeal)
                    Text(occupation)
                        .font(.subheadline.bold())
                        .foregroundColor(.btTeal)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.btTeal.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Scrollable list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredOccupations, id: \.self) { occ in
                        Button(action: {
                            occupation = occ
                            occupationSearch = occ
                        }) {
                            HStack {
                                Text(occ)
                                    .font(.subheadline)
                                    .foregroundColor(occupation == occ ? .white : .primary)
                                Spacer()
                                if occupation == occ {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(occupation == occ ? Color.btTeal : Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(occupation == occ ? Color.btTeal : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .frame(maxHeight: 220)
            
            BTButton(title: "Next", action: {
                userSession.occupation = occupation
                curStep = .height
            }, isDisabled: occupation.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var heightStep: some View {
        VStack(spacing: 30) {
            Text("How tall are you?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            HStack(spacing: 10) {
                TextField("170", text: $height)
                    .font(.btHeader)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .frame(width: 100)
                
                Text("cm")
                    .font(.btHeader)
                    .foregroundColor(.gray)
            }
            
            BTButton(title: "Next", action: {
                userSession.height = height
                curStep = .oneLineIntro
            }, isDisabled: height.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    

    

    
    // Helper function removed in favor of BTSelectionButton
    
    var oneLineIntroStep: some View {
        VStack(spacing: 24) {
            Text("Your One-Line Intro")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            Text("Write one sentence that shows off your charm!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .trailing, spacing: 6) {
                BTTextField(placeholder: "e.g. A coffee-loving designer who lives for sunsets ☕", text: $oneLineIntro)
                    .padding(.horizontal, 40)
                    .onChange(of: oneLineIntro) { _, newValue in
                        // Limit to 80 characters
                        if newValue.count > 80 {
                            oneLineIntro = String(newValue.prefix(80))
                        }
                    }
                
                Text("\(oneLineIntro.count)/80")
                    .font(.caption2)
                    .foregroundColor(oneLineIntro.count >= 70 ? .orange : .gray)
                    .padding(.trailing, 44)
            }
            
            BTButton(title: "Next", action: {
                userSession.oneLineIntro = oneLineIntro
                curStep = .selfIntro
            }, isDisabled: oneLineIntro.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var selfIntroStep: some View {
        VStack(spacing: 20) {
            Text("About Me")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            // AI guidance message
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(.btTeal)
                    .font(.subheadline)
                
                Text("Our AI uses this to find your perfect match. Write as accurately and attractively as you can — the better your description, the better your matches!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.btTeal.opacity(0.08))
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
            VStack(alignment: .trailing, spacing: 6) {
                TextEditor(text: $selfIntro)
                    .frame(height: 150)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 40)
                    .onChange(of: selfIntro) { _, newValue in
                        if newValue.count > 500 {
                            selfIntro = String(newValue.prefix(500))
                        }
                    }
                
                HStack {
                    if selfIntro.trimmingCharacters(in: .whitespacesAndNewlines).count < 20 && !selfIntro.isEmpty {
                        Text("Please write at least one full sentence.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    Spacer()
                    Text("\(selfIntro.count)/500")
                        .font(.caption2)
                        .foregroundColor(selfIntro.count >= 450 ? .orange : .gray)
                }
                .padding(.horizontal, 44)
            }
            
            if isSaving {
                ProgressView()
            }
            
            BTButton(title: "Complete Profile", action: {
                userSession.selfIntro = selfIntro
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: birthDate)
                
                let profileData: [String: Any] = [
                    "full_name": fullName,
                    "nickname": nickname,
                    "birth_date": dateString,
                    "gender": gender,
                    "occupation": occupation,
                    "height": height,
                    "one_line_intro": oneLineIntro,
                    "self_intro": selfIntro,
                    "onboarding_step": "mbtiManualInput"
                ]
                
                isSaving = true
                Task {
                    do {
                        try await AuthManager.shared.updateProfile(data: profileData)
                        await MainActor.run {
                            isSaving = false
                            router.navigate(to: .mbtiManualInput)
                        }
                    } catch {
                        print("Error saving profile: \(error)")
                        await MainActor.run {
                            isSaving = false
                            router.navigate(to: .mbtiManualInput)
                        }
                    }
                }
            }, isDisabled: selfIntro.trimmingCharacters(in: .whitespacesAndNewlines).count < 20 || isSaving)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(OnboardingRouter())
}
