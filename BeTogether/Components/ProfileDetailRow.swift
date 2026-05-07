import SwiftUI

/// Reusable row component for displaying profile detail items with icon, title, and value.
struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.btTeal)
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(value == "Not set" ? .gray : .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        
        Divider().padding(.leading, 56)
    }
}
