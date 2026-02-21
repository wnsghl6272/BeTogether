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
                                preferenceButton("Female", selection: $preferredGender)
                                preferenceButton("Male", selection: $preferredGender)
                                preferenceButton("Any", selection: $preferredGender)
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
                        
                        BTButton(title: "Save & Continue") {
                            savePreferences()
                            router.navigate(to: .contactBlocking)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        }
    }
    
    func preferenceButton(_ title: String, selection: Binding<String>) -> some View {
        Button(action: { selection.wrappedValue = title }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(selection.wrappedValue == title ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selection.wrappedValue == title ? Color.btTeal : Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
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

// Simple Range Slider Helper
struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.btTeal)
                    .frame(width: width(for: range, in: geometry), height: 4)
                    .offset(x: offset(for: range.lowerBound, in: geometry))
                
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 20, height: 20)
                    .offset(x: offset(for: range.lowerBound, in: geometry))
                    .gesture(
                        DragGesture().onChanged { value in
                            let location = value.location.x
                            let percentage = location / geometry.size.width
                            let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(percentage)
                            if newValue < range.upperBound - 1 && newValue >= bounds.lowerBound {
                                range = newValue...range.upperBound
                            }
                        }
                    )
                
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 20, height: 20)
                    .offset(x: offset(for: range.upperBound, in: geometry) - 20) // -20 to center on end
                    .gesture(
                        DragGesture().onChanged { value in
                            let location = value.location.x
                            let percentage = location / geometry.size.width
                            let newValue = bounds.lowerBound + (bounds.upperBound - bounds.lowerBound) * Double(percentage)
                            if newValue > range.lowerBound + 1 && newValue <= bounds.upperBound {
                                range = range.lowerBound...newValue
                            }
                        }
                    )
            }
            .frame(height: 20)
        }
    }
    
    func width(for range: ClosedRange<Double>, in geometry: GeometryProxy) -> CGFloat {
        let total = bounds.upperBound - bounds.lowerBound
        let covered = range.upperBound - range.lowerBound
        return geometry.size.width * CGFloat(covered / total)
    }
    
    func offset(for value: Double, in geometry: GeometryProxy) -> CGFloat {
        let total = bounds.upperBound - bounds.lowerBound
        let current = value - bounds.lowerBound
        return geometry.size.width * CGFloat(current / total)
    }
}

#Preview {
    MatchingPreferenceView()
        .environmentObject(UserSessionViewModel())
}
