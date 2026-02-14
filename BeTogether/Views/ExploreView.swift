import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedFilter: String? = nil
    
    let filters = ["All", "MBTI", "Job", "Values", "Hobby"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by interest, job...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterChip(title: filter, isSelected: selectedFilter == filter) {
                                if selectedFilter == filter {
                                    selectedFilter = nil
                                } else {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // User Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(0..<10) { index in
                            ExploreUserCard(index: index)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Subviews

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.btTeal : Color.gray.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct ExploreUserCard: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            // Image Placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(0.8, contentMode: .fill)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                )
                .cornerRadius(15)
                .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("User \(index)")
                        .font(.headline)
                    Spacer()
                    Text("9\(index)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Text("Designer • Seoul")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Tags
                HStack {
                    Text("ENFP")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                    
                    Text("Traveller")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 5)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ExploreView()
}
