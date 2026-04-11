import SwiftUI

struct BlockedContactsManagerView: View {
    @State private var blockedRecords: [AuthManager.BlockedContactRecord] = []
    @State private var isLoading = true
    @State private var showContactPicker = false
    @State private var newContacts: [BlockedContact] = []
    @State private var isSaving = false
    @State private var statusMessage: String? = nil
    
    var body: some View {
        List {
            // Current Blocked Section
            Section {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if blockedRecords.isEmpty && newContacts.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.green)
                        Text("No contacts blocked.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(blockedRecords) { record in
                        HStack {
                            Image(systemName: "person.fill.xmark")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Blocked Contact")
                                    .font(.subheadline)
                                Text(String(record.hashed_phone.prefix(12)) + "...")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .monospaced()
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                unblockContact(record)
                            }) {
                                Text("Unblock")
                                    .font(.caption.bold())
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete(perform: deleteRecords)
                }
            } header: {
                Text("Currently Blocked (\(blockedRecords.count))")
            } footer: {
                Text("Phone numbers are stored as SHA-256 hashes for your privacy. Swipe left to unblock.")
            }
            
            // Pending Section (newly selected contacts)
            if !newContacts.isEmpty {
                Section("Pending Addition") {
                    ForEach(newContacts, id: \.id) { contact in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(.subheadline)
                                Text(contact.phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: {
                                newContacts.removeAll { $0.id == contact.id }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            
            // Add Button
            Section {
                Button(action: {
                    showContactPicker = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(.btTeal)
                        Text("Select Contacts to Block")
                            .foregroundColor(.btTeal)
                    }
                }
                
                if !newContacts.isEmpty {
                    Button(action: saveNewBlocks) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Save \(newContacts.count) Contact(s)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.white)
                        .listRowBackground(Color.btTeal)
                    }
                    .disabled(isSaving)
                    .listRowBackground(Color.btTeal)
                }
            }
            
            // Status
            if let status = statusMessage {
                Section {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Blocked Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactPicker) {
            ContactPicker(selectedContacts: $newContacts)
        }
        .onAppear {
            loadBlockedContacts()
        }
    }
    
    private func loadBlockedContacts() {
        Task {
            do {
                let records = try await AuthManager.shared.fetchBlockedContacts()
                await MainActor.run {
                    self.blockedRecords = records
                    self.isLoading = false
                }
            } catch {
                print("Failed to load blocked contacts: \(error)")
                await MainActor.run { isLoading = false }
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        let toDelete = offsets.map { blockedRecords[$0] }
        blockedRecords.remove(atOffsets: offsets)
        
        Task {
            for record in toDelete {
                try? await AuthManager.shared.deleteBlockedContact(id: record.id)
            }
        }
    }
    
    private func unblockContact(_ record: AuthManager.BlockedContactRecord) {
        withAnimation {
            blockedRecords.removeAll { $0.id == record.id }
        }
        Task {
            try? await AuthManager.shared.deleteBlockedContact(id: record.id)
        }
    }
    
    private func saveNewBlocks() {
        isSaving = true
        let hashes = newContacts.map { $0.hashedNumber }.filter { !$0.isEmpty }
        
        Task {
            do {
                try await AuthManager.shared.saveBlockedContacts(hashes: hashes)
                await MainActor.run {
                    statusMessage = "\(newContacts.count) contact(s) blocked successfully."
                    newContacts.removeAll()
                    isSaving = false
                }
                // Reload the list
                loadBlockedContacts()
            } catch {
                await MainActor.run {
                    statusMessage = "Failed to save: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BlockedContactsManagerView()
    }
}
