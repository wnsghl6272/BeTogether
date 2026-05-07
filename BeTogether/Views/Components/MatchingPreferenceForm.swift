import SwiftUI

struct MatchingPreferenceForm: View {
    @Binding var locationText: String
    @Binding var preferredGender: String
    @Binding var maxAge: Double
    @Binding var maxDistance: Double
    @Binding var selectedDrinkingFilters: Set<String>
    @Binding var selectedSmokingFilters: Set<String>
    
    var onDetectLocation: (() -> Void)?
    
    let genderOptions = ["Female", "Male", "Other", "Any"]
    let drinkingOptions = ["Non-drinker", "Socially", "Reviewer"]
    let smokingOptions = ["Non-smoker", "Smoker", "Electronic Cigarette", "Trying to quit"]
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Location
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Location")
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.btTeal)
                    Text(locationText.isEmpty ? "Detecting..." : locationText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    if let onDetectLocation = onDetectLocation {
                        Button(action: onDetectLocation) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.btTeal)
                                .font(.caption)
                        }
                    } else {
                        Image(systemName: "location.circle")
                            .foregroundColor(.btTeal)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
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
            
            // Gender Preference
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Preferred Gender")
                
                HStack(spacing: 10) {
                    ForEach(genderOptions, id: \.self) { option in
                        BTToggleButton(title: option, selection: $preferredGender)
                    }
                }
            }
            
            // Age Range
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    sectionHeader("Age Range")
                    Spacer()
                    Text("Up to \(Int(maxAge))")
                        .font(.subheadline.bold())
                        .foregroundColor(.btTeal)
                }
                
                Slider(value: $maxAge, in: 19...50, step: 1)
                    .accentColor(.btTeal)
            }
            
            // Filters - Drinking
            filterSection(title: "Drinking Habit", options: drinkingOptions, selected: $selectedDrinkingFilters)
            
            // Filters - Smoking
            filterSection(title: "Smoking Habit", options: smokingOptions, selected: $selectedSmokingFilters)
            
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.gray)
    }
    
    private func filterSection(title: String, options: [String], selected: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title)
            
            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selected.wrappedValue.contains(option)
                    Text(option)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.btTeal : Color(UIColor.systemBackground))
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
}
