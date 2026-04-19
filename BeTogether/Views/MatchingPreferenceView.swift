import SwiftUI

struct MatchingPreferenceView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Preferences State
    @State private var locationText: String = "Seoul"
    @State private var maxDistance: Double = 10
    @State private var preferredGender: String = "Any"
    @State private var ageRange: ClosedRange<Double> = 20...35
    @State private var prioritizeActiveUsers: Bool = false
    
    // Lifestyle Filter State
    @State private var selectedDrinkingFilters: Set<String> = []
    @State private var selectedSmokingFilters: Set<String> = []
    @State private var isSaving: Bool = false
    
    let drinkingOptions = ["Non-drinker", "Socially", "Reviewer"]
    let smokingOptions = ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]
    
    // MBTI Filter State
    let mbtiTypes = [
        "ISTJ", "ISFJ", "INFJ", "INTJ",
        "ISTP", "ISFP", "INFP", "INTP",
        "ESTP", "ESFP", "ENFP", "ENTP",
        "ESTJ", "ESFJ", "ENFJ", "ENTJ"
    ]
    @State private var selectedMBTI: Set<String> = []
    
    var body: some View {
        NavigationView {
        ZStack {
            Color.btIvory.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Header
                HStack {
                    Text("Matching Preferences")
                        .font(.btHeader)
                        .foregroundColor(.btTeal)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Location (Locked for now)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.btTeal)
                                Text(locationText)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Distance
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Max Distance")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(maxDistance))km")
                                    .font(.subheadline)
                                    .foregroundColor(.btTeal)
                            }
                            
                            Slider(value: $maxDistance, in: 1...100, step: 1)
                                .accentColor(.btTeal)
                        }
                        
                        // Gender Preference
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preferred Gender")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 10) {
                                BTToggleButton(title: "Female", selection: $preferredGender)
                                BTToggleButton(title: "Male", selection: $preferredGender)
                                BTToggleButton(title: "Any", selection: $preferredGender)
                            }
                        }
                        
                        // Age Range
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Age Range")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(Int(ageRange.lowerBound)) - \(Int(ageRange.upperBound))")
                                    .font(.subheadline)
                                    .foregroundColor(.btTeal)
                            }
                            
                            RangeSlider(range: $ageRange, bounds: 19...50)
                                .frame(height: 40)
                        }
                        
                        // Most recently active
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Prioritize Recently Active", isOn: $prioritizeActiveUsers)
                                .font(.headline)
                                .foregroundColor(.gray)
                                .toggleStyle(SwitchToggleStyle(tint: .btTeal))
                        }
                        
                        // Filters - Drinking
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Okay with Drinking")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            FlowLayout(spacing: 10) {
                                ForEach(drinkingOptions, id: \.self) { option in
                                    let isSelected = selectedDrinkingFilters.contains(option)
                                    Text(option)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.btTeal : Color.white)
                                        .foregroundColor(isSelected ? .white : .btTeal)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.btTeal, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            if isSelected {
                                                selectedDrinkingFilters.remove(option)
                                            } else {
                                                selectedDrinkingFilters.insert(option)
                                            }
                                        }
                                }
                            }
                        }
                        
                        // Filters - Smoking
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Okay with Smoking")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            FlowLayout(spacing: 10) {
                                ForEach(smokingOptions, id: \.self) { option in
                                    let isSelected = selectedSmokingFilters.contains(option)
                                    Text(option)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.btTeal : Color.white)
                                        .foregroundColor(isSelected ? .white : .btTeal)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.btTeal, lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            if isSelected {
                                                selectedSmokingFilters.remove(option)
                                            } else {
                                                selectedSmokingFilters.insert(option)
                                            }
                                        }
                                }
                            }
                        }
                        
                        // MBTI Filter
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Preferred MBTI (Select multiple)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                ForEach(mbtiTypes, id: \.self) { mbti in
                                    Button(action: {
                                        if selectedMBTI.contains(mbti) {
                                            selectedMBTI.remove(mbti)
                                        } else {
                                            selectedMBTI.insert(mbti)
                                        }
                                    }) {
                                        Text(mbti)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(selectedMBTI.contains(mbti) ? .white : .btTeal)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(selectedMBTI.contains(mbti) ? Color.btTeal : Color.white)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.btTeal, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                        
                        if isSaving {
                            ProgressView()
                                .padding(.bottom, 10)
                        }
                        
                        BTButton(title: "Save & Continue") {
                            savePreferences()
                            isSaving = true
                            
                            let preferences: [String: Any] = [
                                "location": locationText,
                                "max_distance": Int(maxDistance),
                                "preferred_gender": preferredGender,
                                "min_age": Int(ageRange.lowerBound),
                                "max_age": Int(ageRange.upperBound),
                                "prioritize_active": prioritizeActiveUsers,
                                "filter_smoking": Array(selectedSmokingFilters),
                                "filter_drinking": Array(selectedDrinkingFilters),
                                "filter_mbti": Array(selectedMBTI)
                            ]
                            
                            Task {
                                do {
                                    try await AuthManager.shared.updateUserTraits(data: ["matching_preferences": preferences])
                                    try await AuthManager.shared.updateProfile(data: ["onboarding_step": "contactBlocking"])
                                    await MainActor.run {
                                        isSaving = false
                                        router.navigate(to: .contactBlocking)
                                    }
                                } catch {
                                    print("Error saving preferences: \(error)")
                                    await MainActor.run {
                                        isSaving = false
                                        router.navigate(to: .contactBlocking)
                                    }
                                }
                            }
                        }
                        .disabled(isSaving)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        }
    }
    
    func savePreferences() {
        userSession.preferredGender = preferredGender
        userSession.minAge = ageRange.lowerBound
        userSession.maxAge = ageRange.upperBound
        userSession.maxDistance = maxDistance
        userSession.prioritizeActiveUsers = prioritizeActiveUsers
        userSession.filterSmoking = Array(selectedSmokingFilters)
        userSession.filterDrinking = Array(selectedDrinkingFilters)
        userSession.filterMBTI = Array(selectedMBTI)
    }
}

#Preview {
    MatchingPreferenceView()
        .environmentObject(UserSessionViewModel())
}
