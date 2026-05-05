import Foundation
import Supabase

struct UserEconomy: Codable, Equatable {
    var userId: UUID
    var coins: Int
    var premiumStatus: Bool
    var lastAttendanceDateStr: String?
    var attendanceDays: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case coins
        case premiumStatus = "premium_status"
        case lastAttendanceDateStr = "last_attendance_date"
        case attendanceDays = "attendance_days"
    }
    
    /// Convert the stored date string to a Date for comparison
    var lastAttendanceDate: Date? {
        guard let str = lastAttendanceDateStr else { return nil }
        // Try multiple formats the DB might return
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: str) { return d }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone.current
        if let d = df.date(from: str) { return d }
        // Try with time component
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let d = df.date(from: str) { return d }
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df.date(from: str)
    }
}

struct EconomyUpdate: Encodable {
    var coins: Int?
    var premium_status: Bool?
    var last_attendance_date: String?
    var attendance_days: Int?
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var economy: UserEconomy?
    @Published var isLoading = false
    
    private let client = AuthManager.shared.client
    
    private init() {}
    
    /// Initialize or fetch economy data for the current user
    func fetchEconomy() async {
        guard let session = try? await client.auth.session else {
            print("StoreManager: No session available")
            return
        }
        let userId = session.user.id
        
        isLoading = true
        do {
            let response: [UserEconomy] = try await client.database
                .from("user_economy")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let data = response.first {
                print("StoreManager: Loaded economy — coins: \(data.coins), days: \(data.attendanceDays)")
                self.economy = data
            } else {
                // Create initial record
                let initial = UserEconomy(userId: userId, coins: 0, premiumStatus: false, lastAttendanceDateStr: nil, attendanceDays: 0)
                try await client.database
                    .from("user_economy")
                    .insert(initial)
                    .execute()
                print("StoreManager: Created new economy record with 0 coins")
                self.economy = initial
            }
        } catch {
            print("StoreManager: Error fetching economy: \(error)")
        }
        isLoading = false
    }
    
    /// Daily Check-in logic
    func checkDailyAttendance() async -> (success: Bool, coinsAdded: Int, message: String) {
        guard let session = try? await client.auth.session,
              var currentEconomy = economy else { return (false, 0, "Not logged in") }
        let userId = session.user.id
        
        let calendar = Calendar.current
        let today = Date()
        
        // Check if already checked in today
        if let lastDate = currentEconomy.lastAttendanceDate,
           calendar.isDate(lastDate, inSameDayAs: today) {
            return (false, 0, "Already checked in today")
        }
        
        // Increment attendance days (cumulative)
        currentEconomy.attendanceDays += 1
        
        // Calculate reward
        var reward = currentEconomy.premiumStatus ? 10 : 2
        
        if currentEconomy.attendanceDays == 3 {
            reward += 2
            currentEconomy.coins += reward
        } else if currentEconomy.attendanceDays == 5 {
            reward += 2
            currentEconomy.coins += reward
        } else if currentEconomy.attendanceDays >= 7 {
            reward += 4
            currentEconomy.coins += reward
            currentEconomy.attendanceDays = 0 // Reset after 7th day
        } else {
            currentEconomy.coins += reward
        }
        
        // Store today's date as a simple date string matching DB format
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let todayStr = df.string(from: today)
        currentEconomy.lastAttendanceDateStr = todayStr
        
        do {
            let updateData = EconomyUpdate(
                coins: currentEconomy.coins,
                last_attendance_date: todayStr,
                attendance_days: currentEconomy.attendanceDays
            )
            
            try await client.database
                .from("user_economy")
                .update(updateData)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            self.economy = currentEconomy
            return (true, reward, "Checked in! Received \(reward) coins.")
        } catch {
            print("Error updating attendance: \(error)")
            return (false, 0, "Network error")
        }
    }
    
    /// Spend coins for features
    func spendCoins(amount: Int) async -> Bool {
        guard let session = try? await client.auth.session,
              var currentEconomy = economy else { return false }
        let userId = session.user.id
        
        if currentEconomy.coins < amount {
            return false // Not enough coins
        }
        
        currentEconomy.coins -= amount
        
        do {
            try await client.database
                .from("user_economy")
                .update(EconomyUpdate(coins: currentEconomy.coins))
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            self.economy = currentEconomy
            return true
        } catch {
            print("Error spending coins: \(error)")
            return false
        }
    }
    
    // MARK: - Mock IAP
    
    func purchasePremium() async {
        guard let session = try? await client.auth.session,
              var currentEconomy = economy else { return }
        let userId = session.user.id
        
        currentEconomy.premiumStatus = true
        currentEconomy.coins += 50 // Bonus for premium
        
        do {
            try await client.database
                .from("user_economy")
                .update(EconomyUpdate(coins: currentEconomy.coins, premium_status: true))
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            self.economy = currentEconomy
        } catch {
            print("Error purchasing premium: \(error)")
        }
    }
    
    func purchaseCoins(amount: Int) async {
        guard let session = try? await client.auth.session,
              var currentEconomy = economy else { return }
        let userId = session.user.id
        
        currentEconomy.coins += amount
        
        do {
            try await client.database
                .from("user_economy")
                .update(EconomyUpdate(coins: currentEconomy.coins))
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            self.economy = currentEconomy
        } catch {
            print("Error purchasing coins: \(error)")
        }
    }
}
