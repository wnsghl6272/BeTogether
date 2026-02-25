import SwiftUI

struct MatchingPreferenceView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    
    // Preferences State
    @State private var preferredGender: String = "Any"
    @State private var ageRange: ClosedRange<Double> = 20...35
    @State private var maxDistance: Double = 10
    @State private var filterSmoking: Bool = false
    @State private var filterDrinking: Bool = false
    @State private var isSaving: Bool = false
    
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
                                .frame(height: 40) // Simplified slider placeholder
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
                        
                        // Filters
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Lifestyle Filters")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Toggle("Avoid Smokers", isOn: $filterSmoking)
                                .toggleStyle(SwitchToggleStyle(tint: .btTeal))
                            
                            Toggle("Avoid Drinkers", isOn: $filterDrinking)
                                .toggleStyle(SwitchToggleStyle(tint: .btTeal))
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
                                "preferred_gender": preferredGender,
                                "min_age": Int(ageRange.lowerBound),
                                "max_age": Int(ageRange.upperBound),
                                "max_distance": Int(maxDistance),
                                "filter_smoking": filterSmoking,
                                "filter_drinking": filterDrinking,
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
    
    // Replaced inline helper with BTToggleButton
    
    func savePreferences() {
        userSession.preferredGender = preferredGender
        userSession.minAge = ageRange.lowerBound
        userSession.maxAge = ageRange.upperBound
        userSession.maxDistance = maxDistance
        userSession.filterSmoking = filterSmoking
        userSession.filterDrinking = filterDrinking
        userSession.filterMBTI = Array(selectedMBTI)
    }
}

#Preview {
    MatchingPreferenceView()
        .environmentObject(UserSessionViewModel())
}
