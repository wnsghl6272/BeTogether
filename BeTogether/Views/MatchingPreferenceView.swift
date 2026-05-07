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
                            
                            MatchingPreferenceForm(
                                locationText: $locationText,
                                preferredGender: $preferredGender,
                                maxAge: $maxAge,
                                maxDistance: $maxDistance,
                                selectedDrinkingFilters: $selectedDrinkingFilters,
                                selectedSmokingFilters: $selectedSmokingFilters,
                                onDetectLocation: nil
                            )                            

                            
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
