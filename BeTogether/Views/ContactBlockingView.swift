import SwiftUI

struct ContactBlockingView: View {
    @EnvironmentObject var userSession: UserSessionViewModel
    @State private var showingContactPicker = false
    @State private var blockedContacts: [String] = [] // Mock data for now
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "hand.raised.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.red)
                        .padding(.top, 40)
                    
                    Text("Block Contacts")
                        .font(.btHeader)
                        .foregroundColor(.black)
                    
                    Text("Don't want to meet someone you know?\nBlock them by phone number.")
                        .font(.btSubheader)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Blocked List Mock
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if blockedContacts.isEmpty {
                            Text("No contacts blocked yet.")
                                .font(.btBody)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 20)
                        } else {
                            ForEach(blockedContacts, id: \.self) { contact in
                                HStack {
                                    Text(contact)
                                        .font(.btBody)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Button(action: {
                                        blockedContacts.removeAll { $0 == contact }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.btIvory)
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxHeight: 200)
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        // In a real app, this would open CNContactPickerViewController
                        // For now, we'll just add a mock contact
                        blockedContacts.append("Mock Contact \(blockedContacts.count + 1)")
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Load Contacts")
                        }
                        .font(.btButton)
                        .foregroundColor(.btTeal)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.btTeal, lineWidth: 1)
                        )
                    }
                    
                    Text("We securely hash phone numbers using SHA-256.\nBeTogether never stores your contacts.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 10)
                    
                    BTButton(title: "Complete & Start") {
                        userSession.advanceToNextStep()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContactBlockingView()
        .environmentObject(UserSessionViewModel())
}
