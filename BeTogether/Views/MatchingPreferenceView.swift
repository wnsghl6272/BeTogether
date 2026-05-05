import SwiftUI
import CoreLocation

struct MatchingPreferenceView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @EnvironmentObject var router: OnboardingRouter
    @StateObject private var permissionManager = PermissionManager.shared
    
    // Preferences State
    @State private var locationText: String = ""
    @State private var maxDistance: Double = 10
    @State private var preferredGender: String = "Any"
    @State private var maxAge: Double = 35
    @State private var prioritizeActiveUsers: Bool = false
    
    // Lifestyle Filter State
    @State private var selectedDrinkingFilters: Set<String> = []
    @State private var selectedSmokingFilters: Set<String> = []

    @State private var isSaving: Bool = false
    
    let genderOptions = ["Female", "Male", "Other", "Any"]
    let drinkingOptions = ["Non-drinker", "Socially", "Reviewer"]
    let smokingOptions = ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]

    
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
                            
                            // Location (Detected)
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Location")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.btTeal)
                                    Text(locationText.isEmpty ? "Detecting..." : locationText)
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "location.circle")
                                        .foregroundColor(.btTeal)
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
                                    ForEach(genderOptions, id: \.self) { option in
                                        BTToggleButton(title: option, selection: $preferredGender)
                                    }
                                }
                            }
                            
                            // Age Range
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Age Range")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("Up to \(Int(maxAge))")
                                        .font(.subheadline)
                                        .foregroundColor(.btTeal)
                                }
                                
                                Slider(value: $maxAge, in: 19...50, step: 1)
                                    .accentColor(.btTeal)
                            }
                            
                            // Filters - Drinking
                            filterSection(title: "Drinking Habit", options: drinkingOptions, selected: $selectedDrinkingFilters)
                            
                            // Filters - Smoking
                            filterSection(title: "Smoking Habit", options: smokingOptions, selected: $selectedSmokingFilters)
                            

                            
                            Spacer(minLength: 40)
                            
                            if isSaving {
                                ProgressView()
                                    .padding(.bottom, 10)
                            }
                            
                            BTButton(title: "Save & Continue") {
                                saveAndContinue()
                            }
                            .disabled(isSaving)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                prefillFromSession()
                detectLocation()
            }
        }
    }
    
    // MARK: - Filter Section Helper
    private func filterSection(title: String, options: [String], selected: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selected.wrappedValue.contains(option)
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
                                selected.wrappedValue.remove(option)
                            } else {
                                selected.wrappedValue = [option]
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Prefill from LifestyleOptionsView selections
    private func prefillFromSession() {
        // Gender: pre-filled from LifestyleOptionsView
        if !userSession.preferredGender.isEmpty {
            preferredGender = userSession.preferredGender
        }
        // Smoking filter: pre-filled from lifestyle selection
        if !userSession.filterSmoking.isEmpty {
            selectedSmokingFilters = Set(userSession.filterSmoking)
        }
        // Drinking filter: pre-filled from lifestyle selection
        if !userSession.filterDrinking.isEmpty {
            selectedDrinkingFilters = Set(userSession.filterDrinking)
        }
    }
    
    // MARK: - Location
    private func detectLocation() {
        permissionManager.requestCurrentLocation()
        // Listen for city updates
        if !permissionManager.currentCity.isEmpty {
            locationText = permissionManager.currentCity
        } else {
            // Observe changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if !permissionManager.currentCity.isEmpty {
                    locationText = permissionManager.currentCity
                } else {
                    locationText = "Location unavailable"
                }
            }
        }
    }
    
    // MARK: - Save
    private func saveAndContinue() {
        isSaving = true
        
        // Update userSession
        userSession.preferredGender = preferredGender
        userSession.maxAge = maxAge
        userSession.maxDistance = maxDistance
        userSession.prioritizeActiveUsers = prioritizeActiveUsers
        userSession.filterSmoking = Array(selectedSmokingFilters)
        userSession.filterDrinking = Array(selectedDrinkingFilters)
        
        let preferences: [String: Any] = [
            "location": locationText,
            "max_distance": Int(maxDistance),
            "preferred_gender": preferredGender,
            "max_age": Int(maxAge),
            "prioritize_active": prioritizeActiveUsers,
            "filter_smoking": Array(selectedSmokingFilters),
            "filter_drinking": Array(selectedDrinkingFilters),

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
}

#Preview {
    MatchingPreferenceView()
        .environmentObject(UserSessionViewModel())
}
