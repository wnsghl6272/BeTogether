import SwiftUI
import CoreLocation

struct MatchingPreferenceEditView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var permissionManager = PermissionManager.shared
    
    @State private var locationText: String = ""
    @State private var preferredGender: String = "Any"
    @State private var maxAge: Double = 35
    @State private var maxDistance: Double = 10
    @State private var prioritizeActiveUsers: Bool = false
    @State private var selectedSmokingFilters: Set<String> = []
    @State private var selectedDrinkingFilters: Set<String> = []

    
    @State private var isSaving = false
    @State private var isLoading = true
    
    let genderOptions = ["Female", "Male", "Other", "Any"]
    let drinkingOptions = ["Non-drinker", "Socially", "Reviewer"]
    let smokingOptions = ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    
                    MatchingPreferenceForm(
                        locationText: $locationText,
                        preferredGender: $preferredGender,
                        maxAge: $maxAge,
                        maxDistance: $maxDistance,
                        selectedDrinkingFilters: $selectedDrinkingFilters,
                        selectedSmokingFilters: $selectedSmokingFilters,
                        onDetectLocation: {
                            detectLocation()
                        }
                    )                    

                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Matching Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { savePreferences() }
                        .fontWeight(.bold)
                        .foregroundColor(.btTeal)
                        .disabled(isSaving)
                }
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.2)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(ProgressView("Loading..."))
                }
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
            .onAppear {
                loadExistingPreferences()
                detectLocation()
            }
        }
    }
    
    // MARK: - Helpers
    
    
    
    // MARK: - Location
    private func detectLocation() {
        permissionManager.requestCurrentLocation()
        if !permissionManager.currentCity.isEmpty {
            locationText = permissionManager.currentCity
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if !permissionManager.currentCity.isEmpty {
                    locationText = permissionManager.currentCity
                } else {
                    locationText = "Location unavailable"
                }
            }
        }
    }
    
    // MARK: - Data
    
    private func loadExistingPreferences() {
        Task {
            guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
                  let userId = AuthManager.shared.currentUserId else {
                await MainActor.run { isLoading = false }
                return
            }
            
            do {
                struct TraitResult: Decodable { let matching_preferences: [String: AnyCodable]? }
                let traits: [TraitResult] = try await AuthManager.shared.client.from("user_traits")
                    .select("matching_preferences")
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if let prefs = traits.first?.matching_preferences {
                    await MainActor.run {
                        if let g = prefs["preferred_gender"]?.value as? String { preferredGender = g }
                        if let max = prefs["max_age"]?.value as? Double { maxAge = max }
                        else if let max = prefs["max_age"]?.value as? Int { maxAge = Double(max) }
                        if let dist = prefs["max_distance"]?.value as? Double { maxDistance = dist }
                        else if let dist = prefs["max_distance"]?.value as? Int { maxDistance = Double(dist) }
                        if let active = prefs["prioritize_active"]?.value as? Bool { prioritizeActiveUsers = active }
                        if let loc = prefs["location"]?.value as? String, !loc.isEmpty { locationText = loc }
                        
                        // Array-based filters
                        if let smokeArr = prefs["filter_smoking"]?.value as? [String] { selectedSmokingFilters = Set(smokeArr) }
                        if let drinkArr = prefs["filter_drinking"]?.value as? [String] { selectedDrinkingFilters = Set(drinkArr) }

                    }
                }
            } catch {
                print("Failed to load preferences: \(error)")
            }
            
            await MainActor.run { isLoading = false }
        }
    }
    
    private func savePreferences() {
        isSaving = true
        let preferences: [String: Any] = [
            "location": locationText,
            "preferred_gender": preferredGender,
            "max_age": Int(maxAge),
            "max_distance": Int(maxDistance),
            "prioritize_active": prioritizeActiveUsers,
            "filter_smoking": Array(selectedSmokingFilters),
            "filter_drinking": Array(selectedDrinkingFilters),

        ]
        
        Task {
            do {
                try await AuthManager.shared.updateUserTraits(data: ["matching_preferences": preferences])
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                print("Failed to save preferences: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}

// MARK: - AnyCodable for JSON decoding
struct AnyCodable: Decodable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) { value = int }
        else if let double = try? container.decode(Double.self) { value = double }
        else if let bool = try? container.decode(Bool.self) { value = bool }
        else if let string = try? container.decode(String.self) { value = string }
        else if let array = try? container.decode([AnyCodable].self) { value = array.map { $0.value } }
        else if let dict = try? container.decode([String: AnyCodable].self) { value = dict.mapValues { $0.value } }
        else { value = NSNull() }
    }
}

#Preview {
    MatchingPreferenceEditView()
}
