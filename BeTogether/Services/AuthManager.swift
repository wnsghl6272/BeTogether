import Foundation
import Supabase

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    let client: SupabaseClient
    /// 폰 OTP 인증 후 저장된 access_token (이메일 업데이트 등에 사용)
    private(set) var currentAccessToken: String?

    private init() {
        self.client = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    // MARK: - Phone (SMS) Authentication
    
    /// OTP SMS를 발송합니다.
    /// URLSession 직접 호출 사용 — Supabase SDK의 signInWithOTP(phone:)은 서버 응답({message:"Otp sent"})을
    /// 파싱하지 못하고 -1017 에러를 내뱉는 SDK 버그가 있어 우회합니다.
    func sendSMSOTP(phone: String) async throws {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/otp") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["phone": phone])
        
        // ephemeral 세션 사용 — URLSession.shared는 기존 HTTP/2 연결을 재사용하다가
        // 시뮬레이터에서 끊어진 연결을 잡아 -1005 에러를 유발합니다.
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "OTP 발송 실패 (\(httpResponse.statusCode)): \(errStr)"])
        }
    }
    
    /// SMS OTP를 검증하고 세션을 저장합니다.
    /// Supabase SDK 내부도 shared URLSession을 사용하여 -1005 에러가 발생하므로 ephemeral URLSession으로 우회합니다.
    /// 토큰 파싱 후 SDK의 setSession을 동기적으로 await하여 Keychain에 세션을 안전하게 저장합니다.
    /// 반환값: access_token (프로필 조회에 사용)
    @discardableResult
    func verifySMSOTP(phone: String, token: String) async throws -> String {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/verify") else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "type": "sms",
            "phone": phone,
            "token": token
        ])
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "인증 실패 (\(httpResponse.statusCode)): \(errStr)"])
        }
        
        // 200 OK — 토큰 파싱
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "인증은 성공했으나 토큰을 받지 못했습니다."])
        }
        
        // setSession을 백그라운드로 실행 (SDK 내부 User 파싱/재시도 로직이 UI를 잠그므로)
        self.currentAccessToken = accessToken
        
        Task {
            do {
                try await self.client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
            } catch {
                print("setSession warning: \(error)")
            }
        }
        
        return accessToken
    }
    
    // MARK: - Profile & Traits Query and Update
    
    private func getUserIdFromToken() -> String? {
        guard let token = currentAccessToken else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
        while base64.count % 4 != 0 { base64 += "=" }
        guard let payloadData = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let sub = payload["sub"] as? String else { return nil }
        return sub
    }
    
    /// 인증 완료 후 profiles 테이블에서 유저 status와 onboarding_step을 조회합니다.
    func fetchProfileData(accessToken: String) async -> (status: String, onboardingStep: String?) {
        do {
            self.currentAccessToken = accessToken
            guard let sub = getUserIdFromToken() else { return ("onboarding", nil) }
            
            // Supabase REST API로 profiles 테이블 직접 조회
            let urlStr = "\(Config.supabaseURL.absoluteString)/rest/v1/profiles?id=eq.\(sub)&select=status,onboarding_step"
            guard let url = URL(string: urlStr) else { return ("onboarding", nil) }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let session = URLSession(configuration: .ephemeral)
            let (data, _) = try await session.data(for: request)
            
            if let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstRow = rows.first {
                let status = firstRow["status"] as? String ?? "onboarding"
                let step = firstRow["onboarding_step"] as? String
                print("fetchProfileData: status=\(status), step=\(step ?? "nil")")
                return (status, step)
            }
            
            return ("onboarding", nil)
        } catch {
            print("fetchProfileData error: \(error)")
            return ("onboarding", nil)
        }
    }
    
    /// profiles 테이블을 업데이트합니다 (예: 이메일, 닉네임, onboarding_step 등).
    func updateProfile(data: [String: Any]) async throws {
        guard let sub = getUserIdFromToken(), let token = currentAccessToken else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Require authentication"])
        }
        
        let urlStr = "\(Config.supabaseURL.absoluteString)/rest/v1/profiles?id=eq.\(sub)"
        guard let url = URL(string: urlStr) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Return minimal representation (Supabase defaults to representation, which is sometimes unnecessary)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        
        let session = URLSession(configuration: .ephemeral)
        let (responseData, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: responseData, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Profile update failed: \(errStr)"])
        }
    }
    
    /// user_traits 테이블을 업데이트합니다 (예: mbti, answers, matching_preferences 등).
    func updateUserTraits(data: [String: Any]) async throws {
        guard let sub = getUserIdFromToken(), let token = currentAccessToken else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Require authentication"])
        }
        
        let urlStr = "\(Config.supabaseURL.absoluteString)/rest/v1/user_traits?user_id=eq.\(sub)"
        guard let url = URL(string: urlStr) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        
        let session = URLSession(configuration: .ephemeral)
        let (responseData, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: responseData, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Traits update failed: \(errStr)"])
        }
    }
    
    /// 연락처 차단 목록 (해시)을 저장합니다.
    func saveBlockedContacts(hashes: [String]) async throws {
        guard let sub = getUserIdFromToken(), let token = currentAccessToken else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Require authentication"])
        }
        
        guard !hashes.isEmpty else { return }
        
        let urlStr = "\(Config.supabaseURL.absoluteString)/rest/v1/blocked_contacts"
        guard let url = URL(string: urlStr) else { return }
        
        let payload = hashes.map { ["user_id": sub, "hashed_phone": $0] }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal, resolution=ignore-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let session = URLSession(configuration: .ephemeral)
        let (responseData, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: responseData, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to save blocked contacts: \(errStr)"])
        }
    }
    
    // MARK: - Email Authentication (기존 유저에 이메일 추가)
    
    /// 기존 폰 인증 유저에 복구 이메일을 추가합니다.
    /// PUT /auth/v1/user를 사용하여 새 유저를 만들지 않고, 기존 유저의 이메일을 업데이트합니다.
    /// Supabase가 해당 이메일로 확인 코드를 자동 발송합니다.
    func sendEmailOTP(email: String) async throws {
        let email = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard let token = currentAccessToken else {
            throw NSError(domain: "AuthAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "인증 세션이 없습니다. 다시 로그인해주세요."])
        }
        
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email])
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            // 422 = 이미 사용 중인 이메일
            let message = httpResponse.statusCode == 422
                ? "This email is already in use."
                : "이메일 등록 실패 (\(httpResponse.statusCode)): \(errStr)"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
    
    /// 이메일 변경 OTP를 검증합니다. type: email_change 사용.
    func verifyEmailOTP(email: String, token: String) async throws {
        guard let authToken = currentAccessToken else {
            throw NSError(domain: "AuthAPI", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "인증 세션이 없습니다."])
        }
        
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/verify") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "type": "email_change",
            "token": token,
            "email": email.lowercased().trimmingCharacters(in: .whitespaces)
        ])
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            throw NSError(domain: "AuthAPI", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "이메일 인증 실패 (\(httpResponse.statusCode)): \(errStr)"])
        }
        
        // 인증 성공 시 profiles 테이블에도 이메일 저장
        try await updateProfile(data: ["email": email])
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
    
    // MARK: - RPC: Check Email Exists
    func checkEmailExists(email: String) async throws -> Bool {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/rest/v1/rpc/check_email_exists") else {
            throw NSError(domain: "AuthAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["lookup_email": email.lowercased().trimmingCharacters(in: .whitespaces)])
        
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errStr = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("checkEmailExists HTTP Error: \(httpResponse.statusCode) - \(errStr)")
            return false // 에러 시 기본으로 false 처리 (또는 에러 throw 가능)
        }
        
        if let resultString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return resultString == "true"
        }
        
        return false
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
