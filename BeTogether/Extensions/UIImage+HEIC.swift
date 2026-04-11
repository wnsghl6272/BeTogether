import UIKit
import AVFoundation

extension UIImage {
    /// Encode UIImage to HEIC data (50% smaller than JPEG at similar quality)
    /// Returns nil if HEIC encoding is not available
    func heicData(compressionQuality: CGFloat = 0.7) -> Data? {
        guard let cgImage = self.cgImage else { return nil }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            AVFileType.heic as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
}
