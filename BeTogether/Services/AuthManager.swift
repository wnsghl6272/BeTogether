import Foundation
import Supabase

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )
    }
    
    // MARK: - Phone (SMS) Authentication
    func sendSMSOTP(phone: String) async throws {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/otp") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["phone": phone]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errString = String(data: data, encoding: .utf8) ?? "Unknown Error"
                throw NSError(domain: "AuthAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server failed with \(httpResponse.statusCode): \(errString)"])
            }
        }
    }
    
    func verifySMSOTP(phone: String, token: String) async throws {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/verify") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "type": "sms",
            "phone": phone,
            "token": token
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            if !(200...299).contains(httpResponse.statusCode) {
                let errString = String(data: data, encoding: .utf8) ?? "Unknown Error"
                throw NSError(domain: "AuthAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Verify failed (\(httpResponse.statusCode)): \(errString)"])
            }
        }
        
        // If data is empty or not valid JSON, but we got a 200 OK, it's still a success.
        // Supabase sets the auth cookie implicitly on the Edge sometimes.
        if data.isEmpty { return }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // If the response contains an error message inside a 200 OK (some edge cases), catch it
                if let msg = json["msg"] as? String {
                    throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                
                // If it successfully returns session tokens, manually update the client
                if let sessionToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String {
                    // Execute setSession in a detached Task so it doesn't block verifySMSOTP from returning.
                    // Supabase Swift SDK has a known bug where `GET /user` internal retry logic hangs for 4+ seconds
                    // if it fails to decode the User object, completely freezing the UI navigation.
                    Task {
                        do {
                            try await client.auth.setSession(accessToken: sessionToken, refreshToken: refreshToken)
                        } catch {
                            print("setSession threw an error (likely User parse error) but OTP was fully verified: \(error)")
                        }
                    }
                }
            }
        } catch {
            print("Failed to decode successful verify response (probably empty or different format): \(error)")
            // If the JSON parsing itself fails, we still consider the OTP verified because the server returned 200 OK.
        }
    }
    
    // MARK: - Email Authentication
    func sendEmailOTP(email: String) async throws {
        try await client.auth.signInWithOTP(email: email)
    }
    
    func verifyEmailOTP(email: String, token: String) async throws {
        let _ = try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
    }
    
    // MARK: - Edge Function: Check User Exists
    func checkUserExists(phone: String) async throws -> Bool {
        struct CheckPhoneRequest: Codable {
            let phone: String
        }
        struct CheckPhoneResponse: Codable {
            let exists: Bool
        }
        
        let response: CheckPhoneResponse = try await client.functions.invoke(
            "check-user-exists",
            options: FunctionInvokeOptions(
                body: CheckPhoneRequest(phone: phone)
            )
        )
        return response.exists
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
