import SwiftUI

struct MatchingPreferenceEditView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var preferredGender: String = "Any"
    @State private var minAge: Double = 20
    @State private var maxAge: Double = 35
    @State private var maxDistance: Double = 10
    @State private var filterSmoking: Bool = false
    @State private var filterDrinking: Bool = false
    @State private var selectedMBTI: Set<String> = []
    
    @State private var isSaving = false
    @State private var isLoading = true
    
    let mbtiTypes = [
        "ISTJ", "ISFJ", "INFJ", "INTJ",
        "ISTP", "ISFP", "INFP", "INTP",
        "ESTP", "ESFP", "ENFP", "ENTP",
        "ESTJ", "ESFJ", "ENFJ", "ENTJ"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Gender Preference
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Preferred Gender")
                        
                        HStack(spacing: 10) {
                            genderPill("Female")
                            genderPill("Male")
                            genderPill("Any")
                        }
                    }
                    
                    // Age Range
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionHeader("Age Range")
                            Spacer()
                            Text("\(Int(minAge)) - \(Int(maxAge))")
                                .font(.subheadline.bold())
                                .foregroundColor(.btTeal)
                        }
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("Min")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Slider(value: $minAge, in: 19...49, step: 1) { _ in
                                    if minAge > maxAge { maxAge = minAge }
                                }
                                .accentColor(.btTeal)
                            }
                            VStack {
                                Text("Max")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Slider(value: $maxAge, in: 20...50, step: 1) { _ in
                                    if maxAge < minAge { minAge = maxAge }
                                }
                                .accentColor(.btTeal)
                            }
                        }
                    }
                    
                    // Distance
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            sectionHeader("Max Distance")
                            Spacer()
                            Text("\(Int(maxDistance))km")
                                .font(.subheadline.bold())
                                .foregroundColor(.btTeal)
                        }
                        
                        Slider(value: $maxDistance, in: 1...100, step: 1)
                            .accentColor(.btTeal)
                    }
                    
                    // Lifestyle Filters
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Lifestyle Filters")
                        
                        Toggle("Avoid Smokers", isOn: $filterSmoking)
                            .toggleStyle(SwitchToggleStyle(tint: .btTeal))
                        
                        Toggle("Avoid Drinkers", isOn: $filterDrinking)
                            .toggleStyle(SwitchToggleStyle(tint: .btTeal))
                    }
                    
                    // MBTI Filter
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Preferred MBTI")
                        Text("Leave empty for no filter")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                            ForEach(mbtiTypes, id: \.self) { mbti in
                                Button(action: {
                                    if selectedMBTI.contains(mbti) {
                                        selectedMBTI.remove(mbti)
                                    } else {
                                        selectedMBTI.insert(mbti)
                                    }
                                }) {
                                    Text(mbti)
                                        .font(.caption.bold())
                                        .foregroundColor(selectedMBTI.contains(mbti) ? .white : .btTeal)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedMBTI.contains(mbti) ? Color.btTeal : Color(.systemBackground))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.btTeal, lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
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
            .onAppear { loadExistingPreferences() }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private func genderPill(_ title: String) -> some View {
        Button(action: { preferredGender = title }) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(preferredGender == title ? .white : .btTeal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(preferredGender == title ? Color.btTeal : Color(.systemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.btTeal, lineWidth: 1)
                )
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
                        if let min = prefs["min_age"]?.value as? Double { minAge = min }
                        else if let min = prefs["min_age"]?.value as? Int { minAge = Double(min) }
                        if let max = prefs["max_age"]?.value as? Double { maxAge = max }
                        else if let max = prefs["max_age"]?.value as? Int { maxAge = Double(max) }
                        if let dist = prefs["max_distance"]?.value as? Double { maxDistance = dist }
                        else if let dist = prefs["max_distance"]?.value as? Int { maxDistance = Double(dist) }
                        if let smoke = prefs["filter_smoking"]?.value as? Bool { filterSmoking = smoke }
                        if let drink = prefs["filter_drinking"]?.value as? Bool { filterDrinking = drink }
                        if let mbtiArray = prefs["filter_mbti"]?.value as? [String] { selectedMBTI = Set(mbtiArray) }
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
            "preferred_gender": preferredGender,
            "min_age": Int(minAge),
            "max_age": Int(maxAge),
            "max_distance": Int(maxDistance),
            "filter_smoking": filterSmoking,
            "filter_drinking": filterDrinking,
            "filter_mbti": Array(selectedMBTI)
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
