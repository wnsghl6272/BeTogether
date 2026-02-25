import SwiftUI

struct BTSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.btButton)
                .foregroundColor(isSelected ? .white : .btTeal)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.btTeal : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.btTeal, lineWidth: 2)
                )
        }
    }
}

struct BTToggleButton: View {
    let title: String
    @Binding var selection: String
    
    var body: some View {
        Button(action: { selection = title }) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(selection == title ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selection == title ? Color.btTeal : Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
}
