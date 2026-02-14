import SwiftUI

struct MatchesView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Segmented Control
                HStack {
                    SegmentButton(title: "Matches", icon: "heart.fill", index: 0, selectedTab: $selectedTab)
                    SegmentButton(title: "Chat", icon: "message.fill", index: 1, selectedTab: $selectedTab)
                    SegmentButton(title: "Report", icon: "chart.bar.fill", index: 2, selectedTab: $selectedTab)
                }
                .padding()
                .background(Color.white)
                
                // Content
                ZStack {
                    if selectedTab == 0 {
                        MatchesListView()
                    } else if selectedTab == 1 {
                        ChatListView()
                    } else {
                        CompatibilityReportView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Connections")
                        .font(.btHeader)
                }
            }
        }
    }
}

// MARK: - Subviews

struct MatchesListView: View {
    let mockMatches = ["Alice", "Bob", "Charlie", "David"]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                ForEach(0..<10) { index in
                    VStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                        
                        Text("User \(index)")
                            .font(.headline)
                        
                        Text("95% Match")
                            .font(.caption)
                            .foregroundColor(.btTeal)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
    }
}

struct ChatListView: View {
    var body: some View {
        List(0..<5) { index in
            HStack(spacing: 15) {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(Text("U\(index)").bold())
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("User \(index)")
                        .font(.headline)
                    Text("Hey, how is it going?")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text("2m ago")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
        .listStyle(.plain)
    }
}

struct CompatibilityReportView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Weekly Compatibility Report")
                    .font(.title2.bold())
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Top Matches")
                        .font(.headline)
                    
                    HStack {
                        ReportCard(title: "Best MBTI", value: "ENFP", color: .purple)
                        ReportCard(title: "Activity", value: "Hiking", color: .green)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

struct ReportCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SegmentButton: View {
    let title: String
    let icon: String // Added icon property
    let index: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                // Icon + Text
                HStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(title)
                }
                .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium))
                .foregroundColor(selectedTab == index ? .black : .gray)
                
                if selectedTab == index {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MatchesView()
}
