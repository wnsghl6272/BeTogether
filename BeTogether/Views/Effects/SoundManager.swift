import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {}
    
    func playSound(named soundName: String, restart: Bool = true) {
        // Check if sound is already loaded
        if let player = audioPlayers[soundName] {
             if player.isPlaying {
                 if restart {
                     player.currentTime = 0
                 } else {
                     return // Already playing, don't restart
                 }
             }
             player.play()
             return
         }
        
        // Load sound
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file not found: \(soundName).mp3")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            audioPlayers[soundName] = player
        } catch {
            print("Error playing sound \(soundName): \(error.localizedDescription)")
        }
    }
    
    // Optional: Preload sounds to reduce latency on first play
    func preloadSounds(_ soundNames: [String]) {
        for name in soundNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[name] = player
                } catch {
                    print("Error preloading sound \(name): \(error.localizedDescription)")
                }
            }
        }
    }
}
