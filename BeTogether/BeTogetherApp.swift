import SwiftUI

@main
struct BeTogetherApp: App {
    @StateObject private var userSession = UserSessionViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
        }
    }
}
