import SwiftUI

/// A reusable sheet for searching and selecting an occupation from a predefined list.
struct OccupationPickerSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let occupationList: [String]
    @Binding var selectedOccupation: String
    @Binding var occupationSearch: String
    
    var filteredOccupations: [String] {
        if occupationSearch.isEmpty { return occupationList }
        return occupationList.filter { $0.localizedCaseInsensitiveContains(occupationSearch) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search occupation...", text: $occupationSearch)
                        .autocapitalization(.words)
                    
                    if !occupationSearch.isEmpty {
                        Button(action: { occupationSearch = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Results list
                List(filteredOccupations, id: \.self) { occ in
                    Button(action: {
                        selectedOccupation = occ
                        occupationSearch = occ
                        dismiss()
                    }) {
                        HStack {
                            Text(occ)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedOccupation == occ {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.btTeal)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Occupation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.btTeal)
                }
            }
        }
    }
}
