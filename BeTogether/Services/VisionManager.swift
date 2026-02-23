import Foundation
import Vision
import UIKit

class VisionManager {
    static let shared = VisionManager()
    
    // Returns true if exactly one face is detected in the image
    func detectSingleFace(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    print("Face detection error: \(error)")
                    continuation.resume(returning: false)
                    return
                }
                let results = request.results as? [VNFaceObservation] ?? []
                // We want exactly 1 face for a good profile picture
                continuation.resume(returning: results.count == 1)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform face detection: \(error)")
                continuation.resume(returning: false)
            }
        }
    }
}
