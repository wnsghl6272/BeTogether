import SwiftUI

struct AddFriendSheet: View {
    @Binding var nickname: String
    @Binding var status: String?
    let onAdd: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 44))
                        .foregroundColor(.btTeal)
                    Text("Add Friend")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Enter your friend's unique nickname")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                HStack {
                    Image(systemName: "at")
                        .foregroundColor(.gray)
                    TextField("Nickname", text: $nickname)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button(action: onAdd) {
                    Text("Add Friend")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nickname.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.btTeal)
                        .cornerRadius(14)
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)
                
                if let status = status {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("Error") || status.contains("not found") ? .red : .green)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}
