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
    
    // New Fields
    let job: String
    let height: Int
    let university: String
    let drinking: String
    let smoking: String
    let oneLineIntro: String
    let selfIntro: String
}

extension User {
    static let mockUsers: [User] = [
        User(name: "Ji-min", age: 24, region: "Gangnam", distance: 3, mbti: "ESFP", isOnline: true, isVerified: true, imageName: "profile_korean_1", job: "Designer", height: 165, university: "Seoul Nat'l Univ", drinking: "Socially", smoking: "Non-smoker", oneLineIntro: "Smiling makes everything better!", selfIntro: "Hi, I'm a designer who loves cafes and art exhibitions."),
        User(name: "Sakura", age: 22, region: "Tokyo", distance: 1200, mbti: "ENFP", isOnline: false, isVerified: true, imageName: "profile_japanese_1", job: "Student", height: 160, university: "Waseda Univ", drinking: "Non-drinker", smoking: "Non-smoker", oneLineIntro: "Let's go on an adventure!", selfIntro: "Exchange student from Tokyo. Love exploring new places."),
        User(name: "Su-jin", age: 26, region: "Itaewon", distance: 8, mbti: "ENTJ", isOnline: true, isVerified: false, imageName: "profile_korean_1", job: "Marketer", height: 168, university: "Yonsei Univ", drinking: "Reviewer", smoking: "Non-smoker", oneLineIntro: "Work hard, play hard.", selfIntro: "Passionate marketer looking for someone ambitious."),
        User(name: "Aoi", age: 23, region: "Osaka", distance: 1100, mbti: "ISFP", isOnline: true, isVerified: true, imageName: "profile_japanese_1", job: "Florist", height: 158, university: "Osaka Arts", drinking: "Socially", smoking: "Electronic", oneLineIntro: "Flowers are my language.", selfIntro: "I love nature and quiet walks."),
        User(name: "Ye-wook", age: 25, region: "Jamsil", distance: 12, mbti: "INFJ", isOnline: false, isVerified: true, imageName: "profile_korean_1", job: "Writer", height: 162, university: "Korea Univ", drinking: "Socially", smoking: "Non-smoker", oneLineIntro: "Writing my own story.", selfIntro: "Deep conversations over coffee are my favorite."),
        User(name: "Hana", age: 27, region: "Kyoto", distance: 1150, mbti: "INTJ", isOnline: true, isVerified: true, imageName: "profile_japanese_1", job: "Researcher", height: 166, university: "Kyoto Univ", drinking: "Non-drinker", smoking: "Non-smoker", oneLineIntro: "Curious about the world.", selfIntro: "Science researcher. Logical but caring."),
        User(name: "Ji-u", age: 21, region: "Konkuk", distance: 4, mbti: "ENFJ", isOnline: false, isVerified: false, imageName: "profile_korean_1", job: "Barista", height: 163, university: "Konkuk Univ", drinking: "Socially", smoking: "Non-smoker", oneLineIntro: "Coffee and warm vibes.", selfIntro: "Making the best latte art in town!"),
        User(name: "Seo-yun", age: 24, region: "Gangnam", distance: 3, mbti: "ESTP", isOnline: true, isVerified: true, imageName: "profile_japanese_1", job: "Trainer", height: 170, university: "Sports Univ", drinking: "Reviewer", smoking: "Smoker", oneLineIntro: "Fitness is life!", selfIntro: "Personal trainer. Let's workout together!"),
        User(name: "Yu-jin", age: 28, region: "Pangyo", distance: 20, mbti: "ISTJ", isOnline: false, isVerified: true, imageName: "profile_korean_1", job: "Developer", height: 164, university: "KAIST", drinking: "Socially", smoking: "Non-smoker", oneLineIntro: "Code and cats.", selfIntro: "Backend developer. I like organized plans."),
        User(name: "Yuna", age: 22, region: "Shibuya", distance: 1205, mbti: "INFP", isOnline: true, isVerified: true, imageName: "profile_japanese_1", job: "Artist", height: 159, university: "Art College", drinking: "Non-drinker", smoking: "Non-smoker", oneLineIntro: "Dreaming in colors.", selfIntro: "Freelance illustrator. I love rainy days.")
    ]
}
