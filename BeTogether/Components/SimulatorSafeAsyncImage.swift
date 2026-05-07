import SwiftUI

/// A reusable async image loader that handles loading, error, and placeholder states.
/// Works reliably in both Simulator and device environments.
struct SimulatorSafeAsyncImage<Content: View, Placeholder: View, ErrorView: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let errorView: (Error) -> ErrorView

    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        ZStack {
            if isLoading {
                placeholder()
            } else if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else if let error = error {
                errorView(error)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url = url else {
                isLoading = false
                return
            }
            do {
                let session = URLSession(configuration: .ephemeral)
                let (data, _) = try await session.data(from: url)
                if let image = UIImage(data: data) {
                    self.uiImage = image
                } else {
                    self.error = URLError(.cannotDecodeRawData)
                }
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
}
