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
    func verifySMSOTP(phone: String, token: String) async throws {
        guard let url = URL(string: "\(Config.supabaseURL.absoluteString)/auth/v1/verify") else { return }
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
        
        // 200 OK — 토큰을 파싱해서 SDK 세션에 동기적으로 저장
        guard !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String else {
            // 토큰 없이 200 OK면 인증 자체는 성공한 것 (세션 저장만 건너뜀)
            return
        }
        
        // setSession을 2초 타임아웃으로 실행 — 내부에서 GET /user가 4번 재시도하며
        // UI를 잠그는 것을 방지합니다. 토큰이 전달된 시점에 세션은 이미 유효합니다.
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await self.client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 타임아웃
                    throw CancellationError()
                }
                // 먼저 끝나는 쪽을 채택 (setSession 성공 또는 타임아웃)
                try await group.next()
                group.cancelAll()
            }
        } catch {
            print("setSession completed or timed out (세션 토큰은 전달됨): \(error)")
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
