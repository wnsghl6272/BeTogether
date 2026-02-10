import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    
    enum ProfileStep {
        case birthday
        case nickname
        case gender
        case occupation
        case height
        case university // New
        case drinking   // New
        case smoking    // New
    }
    
    @State private var curStep: ProfileStep = .birthday
    
    // Data States
    @State private var birthDate: Date = Date()
    @State private var nickname: String = ""
    @State private var gender: String = "" // "Male" or "Female"
    @State private var occupation: String = ""
    @State private var height: String = ""
    @State private var university: String = ""     // New
    @State private var drinking: String = ""       // New
    @State private var smoking: String = ""        // New
    
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
    
    var nicknameStep: some View {
        VStack(spacing: 30) {
            Text("What's your nickname?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            BTTextField(placeholder: "Nickname", text: $nickname)
                .padding(.horizontal, 40)
            
            BTButton(title: "Next", action: {
                userSession.nickname = nickname
                curStep = .gender
            }, isDisabled: nickname.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    var genderStep: some View {
        VStack(spacing: 30) {
            Text("Who would you like to meet?")
                .font(.btHeader)
                .foregroundColor(.btTeal)
            
            HStack(spacing: 20) {
                selectionButton(
                    title: "Female",
                    isSelected: gender == "Female",
                    action: { gender = "Female" }
                )
                
                selectionButton(
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
                selectionButton(title: "Non-drinker", isSelected: drinking == "Non-drinker") { drinking = "Non-drinker" }
                selectionButton(title: "Socially", isSelected: drinking == "Socially") { drinking = "Socially" }
                selectionButton(title: "Reviewer", isSelected: drinking == "Reviewer") { drinking = "Reviewer" }
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
                selectionButton(title: "Non-smoker", isSelected: smoking == "Non-smoker") { smoking = "Non-smoker" }
                selectionButton(title: "Smoker", isSelected: smoking == "Smoker") { smoking = "Smoker" }
                selectionButton(title: "Electronic Cigarette", isSelected: smoking == "Electronic Cigarette") { smoking = "Electronic Cigarette" }
                selectionButton(title: "Trying to quit", isSelected: smoking == "Trying to quit") { smoking = "Trying to quit" }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
            
            BTButton(title: "Next", action: {
                userSession.smoking = smoking
                userSession.advanceToNextStep() // Proceed to MBTI
            }, isDisabled: smoking.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    // Helper View Builder for selection buttons
    func selectionButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.btButton)
                .foregroundColor(isSelected ? .white : .btTeal)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.btTeal : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.btTeal, lineWidth: 2)
                )
        }
    }
}

#Preview {
    ProfileSetupView()
        .environmentObject(UserSessionViewModel())
}
