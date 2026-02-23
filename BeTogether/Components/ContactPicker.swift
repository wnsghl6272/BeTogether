import SwiftUI
import ContactsUI
import CryptoKit

struct BlockedContact: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let phoneNumber: String
    
    var hashedNumber: String {
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        // If empty, return something safe
        if cleaned.isEmpty { return "" }
        let data = Data(cleaned.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var selectedContacts: [BlockedContact]
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            var newBlocked = parent.selectedContacts
            
            for contact in contacts {
                let name = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                let displayName = name.isEmpty ? "Unknown" : name
                
                guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else { continue }
                
                // Avoid duplicates by raw number
                if !newBlocked.contains(where: { $0.phoneNumber == phoneNumber }) {
                    let blocked = BlockedContact(name: displayName, phoneNumber: phoneNumber)
                    newBlocked.append(blocked)
                }
            }
            parent.selectedContacts = newBlocked
        }
    }
}
