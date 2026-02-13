import Foundation

struct User: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let region: String
    let distance: Int
    let mbti: String
    let isOnline: Bool
    let isVerified: Bool
    let imageName: String // Asset name
}

extension User {
    static let mockUsers: [User] = [
        User(name: "Ji-min", age: 24, region: "Gangnam", distance: 3, mbti: "ESFP", isOnline: true, isVerified: true, imageName: "profile_korean_1"),
        User(name: "Sakura", age: 22, region: "Tokyo", distance: 1200, mbti: "ENFP", isOnline: false, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Su-jin", age: 26, region: "Itaewon", distance: 8, mbti: "ENTJ", isOnline: true, isVerified: false, imageName: "profile_korean_1"), // Reusing for mock
        User(name: "Aoi", age: 23, region: "Osaka", distance: 1100, mbti: "ISFP", isOnline: true, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Ye-wook", age: 25, region: "Jamsil", distance: 12, mbti: "INFJ", isOnline: false, isVerified: true, imageName: "profile_korean_1"),
        User(name: "Hana", age: 27, region: "Kyoto", distance: 1150, mbti: "INTJ", isOnline: true, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Ji-u", age: 21, region: "Konkuk", distance: 4, mbti: "ENFJ", isOnline: false, isVerified: false, imageName: "profile_korean_1"),
        User(name: "Seo-yun", age: 24, region: "Gangnam", distance: 3, mbti: "ESTP", isOnline: true, isVerified: true, imageName: "profile_japanese_1"), // Mix up
        User(name: "Yu-jin", age: 28, region: "Pangyo", distance: 20, mbti: "ISTJ", isOnline: false, isVerified: true, imageName: "profile_korean_1"),
        User(name: "Yuna", age: 22, region: "Shibuya", distance: 1205, mbti: "INFP", isOnline: true, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Da-in", age: 25, region: "Seoul Stn", distance: 7, mbti: "ESFJ", isOnline: false, isVerified: false, imageName: "profile_korean_1"),
        User(name: "Eun-ji", age: 26, region: "Yeouido", distance: 9, mbti: "ESTJ", isOnline: true, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Hye-jin", age: 23, region: "Mapo", distance: 5, mbti: "ISFJ", isOnline: true, isVerified: true, imageName: "profile_korean_1"),
        User(name: "Riko", age: 29, region: "Roppongi", distance: 1202, mbti: "ENTP", isOnline: false, isVerified: true, imageName: "profile_japanese_1"),
        User(name: "Min-seo", age: 24, region: "Sinsa", distance: 4, mbti: "INTP", isOnline: true, isVerified: true, imageName: "profile_korean_1")
    ]
}
