import Foundation
import Combine

class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var selectedTab: Int = 0
    @Published var activeChatPartner: User? = nil
    @Published var unreadChatCount: Int = 0
    @Published var pendingChatSession: ChatSession? = nil
    
    private init() {}
    
    // Switch to Chat tab (which is index 3 in MainTabView) and set the user
    func navigateToChat(with partner: User) {
        // Tab index for Chat is 3
        activeChatPartner = partner
        selectedTab = 3
    }
}
