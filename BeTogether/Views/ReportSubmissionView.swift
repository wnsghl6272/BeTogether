import SwiftUI

struct ReportSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Optional target user to report
    var targetUserId: String?
    var targetUserName: String?
    
    @State private var selectedReason: String = "Inappropriate Behavior"
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage: String?
    
    var reasons: [String] {
        if targetUserId != nil {
            return [
                "Inappropriate Behavior",
                "Spam or Scam",
                "Fake Profile",
                "Harassment or Bullying",
                "Other"
            ]
        } else {
            return [
                "App Bug / Issue",
                "Other"
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if let targetName = targetUserName {
                    Section(header: Text("Reporting User")) {
                        Text(targetName)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Reason")) {
                    Picker("Select Reason", selection: $selectedReason) {
                        ForEach(reasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Details")) {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                        .overlay(
                            Group {
                                if details.isEmpty {
                                    Text("Please provide more details about your report...")
                                        .foregroundColor(Color(UIColor.placeholderText))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            }, alignment: .topLeading
                        )
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(targetUserId != nil ? "Report User" : "Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit")
                                .bold()
                        }
                    }
                    .disabled(isSubmitting || details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if selectedReason == "Inappropriate Behavior" && targetUserId == nil {
                    selectedReason = "App Bug / Issue"
                }
            }
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your report. Our team will review it shortly.")
            }
        }
    }
    
    private func submitReport() {
        guard !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                guard let token = await AuthManager.shared.fetchCurrentAccessToken(),
                      let reporterId = AuthManager.shared.currentUserId else {
                    await MainActor.run {
                        self.errorMessage = "You must be logged in to submit a report."
                        self.isSubmitting = false
                    }
                    return
                }
                
                let client = AuthManager.shared.client
                
                struct ReportInsert: Encodable {
                    let reporter_id: String
                    let target_id: String?
                    let reason: String
                    let details: String
                }
                
                let reportData = ReportInsert(
                    reporter_id: reporterId,
                    target_id: targetUserId,
                    reason: selectedReason,
                    details: details
                )
                
                try await client.from("reports")
                    .insert(reportData)
                    .setHeader(name: "Authorization", value: "Bearer \(token)")
                    .execute()
                
                await MainActor.run {
                    self.isSubmitting = false
                    self.showSuccessAlert = true
                }
                
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = "Failed to submit report. Please try again."
                }
                print("Report error: \(error)")
            }
        }
    }
}
