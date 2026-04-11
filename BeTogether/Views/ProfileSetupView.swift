import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    enum ProfileStep {
        case birthday
        case nickname
        case gender
        case occupation
        case height
        case university
        case drinking
        case smoking
        case oneLineIntro // New
        case selfIntro    // New
    }
    
    @State private var curStep: ProfileStep = .birthday
    
    // Data States
    @State private var birthDate: Date = Date()
    @State private var nickname: String = ""
    @State private var gender: String = "" // "Male" or "Female"
    @State private var occupation: String = ""
    @State private var height: String = ""
    @State private var university: String = ""
    @State private var drinking: String = ""
    @State private var smoking: String = ""
    @State private var oneLineIntro: String = ""   // New
    @State private var selfIntro: String = ""      // New
    @State private var isSaving: Bool = false
    
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
                case .nickname:
                    nicknameStep
                case .gender:
                    genderStep
                case .occupation:
                    occupationStep
                case .height:
                    heightStep
                case .university:
                    universityStep
                case .drinking:
                    drinkingStep
                case .smoking:
                    smokingStep
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
                curStep = .nickname
            }, isDisabled: !isAgeValid)
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
            Text("Who would you like to meet?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            HStack(spacing: 20) {
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
        VStack(spacing: 30) {
            Text("What is your occupation?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            BTTextField(placeholder: "Designer, Developer, etc.", text: $occupation)
                .padding(.horizontal, 40)
            
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
                curStep = .university
            }, isDisabled: height.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var universityStep: some View {
        VStack(spacing: 30) {
            Text("Which university did you graduate from?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            BTTextField(placeholder: "University Name", text: $university)
                .padding(.horizontal, 40)
            
            BTButton(title: "Next", action: {
                userSession.university = university
                curStep = .drinking
            }, isDisabled: university.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var drinkingStep: some View {
        VStack(spacing: 20) {
            Text("How often do you drink?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                BTSelectionButton(title: "Non-drinker", isSelected: drinking == "Non-drinker") { drinking = "Non-drinker" }
                BTSelectionButton(title: "Socially", isSelected: drinking == "Socially") { drinking = "Socially" }
                BTSelectionButton(title: "Reviewer", isSelected: drinking == "Reviewer") { drinking = "Reviewer" }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            BTButton(title: "Next", action: {
                userSession.drinking = drinking
                curStep = .smoking
            }, isDisabled: drinking.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var smokingStep: some View {
        VStack(spacing: 20) {
            Text("Do you smoke?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 15) {
                BTSelectionButton(title: "Non-smoker", isSelected: smoking == "Non-smoker") { smoking = "Non-smoker" }
                BTSelectionButton(title: "Smoker", isSelected: smoking == "Smoker") { smoking = "Smoker" }
                BTSelectionButton(title: "Electronic Cigarette", isSelected: smoking == "Electronic Cigarette") { smoking = "Electronic Cigarette" }
                BTSelectionButton(title: "Trying to quit", isSelected: smoking == "Trying to quit") { smoking = "Trying to quit" }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            BTButton(title: "Next", action: {
                userSession.smoking = smoking
                curStep = .oneLineIntro
            }, isDisabled: smoking.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    // Helper function removed in favor of BTSelectionButton
    
    var oneLineIntroStep: some View {
        VStack(spacing: 30) {
            Text("Describe yourself in one line")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            BTTextField(placeholder: "e.g. A coffee-loving developer", text: $oneLineIntro)
                .padding(.horizontal, 40)
            
            BTButton(title: "Next", action: {
                userSession.oneLineIntro = oneLineIntro
                curStep = .selfIntro
            }, isDisabled: oneLineIntro.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var selfIntroStep: some View {
        VStack(spacing: 30) {
            Text("Introduce yourself")
                .font(.btHeader)
                .foregroundColor(.btTeal)
                .multilineTextAlignment(.center)
            
            TextEditor(text: $selfIntro)
                .frame(height: 150)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                .padding(.horizontal, 40)
            
            if isSaving {
                ProgressView()
            }
            
            BTButton(title: "Complete Profile", action: {
                userSession.selfIntro = selfIntro
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateString = formatter.string(from: birthDate)
                
                let profileData: [String: Any] = [
                    "nickname": nickname,
                    "birth_date": dateString,
                    "gender": gender,
                    "occupation": occupation,
                    "height": height,
                    "university": university,
                    "drinking": drinking,
                    "smoking": smoking,
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
                            // Should probably show an error alert here
                            router.navigate(to: .mbtiManualInput) // Fallback navigate? Better to show error.
                        }
                    }
                }
            }, isDisabled: selfIntro.isEmpty || isSaving)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(OnboardingRouter())
}
