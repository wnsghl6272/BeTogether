import SwiftUI

struct BTButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.btButton)
                .foregroundColor(.btIvory)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDisabled ? Color.gray : Color.btTeal)
                .cornerRadius(12)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VStack {
        BTButton(title: "Start", action: {})
        BTButton(title: "Next", action: {}, isDisabled: true)
    }
    .padding()
}
