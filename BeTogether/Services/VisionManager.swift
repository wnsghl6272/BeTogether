import Foundation
@preconcurrency import Vision
import UIKit

class VisionManager {
    static let shared = VisionManager()
    
    // Returns true if exactly one face is detected in the image
    func detectSingleFace(in image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        return await withCheckedContinuation { continuation in
            let lock = NSLock()
            var hasResumed = false
            
            // Perform face detection in a background queue since `perform` blocks
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNDetectFaceRectanglesRequest { request, error in
                    lock.lock()
                    guard !hasResumed else {
                        lock.unlock()
                        return
                    }
                    hasResumed = true
                    lock.unlock()
                    
                    if let error = error {
                        print("Face detection error: \(error)")
                        #if targetEnvironment(simulator)
                        print("Simulator fallback: Ignoring Vision crash and allowing upload.")
                        continuation.resume(returning: true)
                        #else
                        continuation.resume(returning: false)
                        #endif
                        return
                    }
                    let results = request.results as? [VNFaceObservation] ?? []
                    continuation.resume(returning: results.count == 1)
                }
                
                // Fix for iOS Simulator "Could not create inference context" error (Code 9).
                // Simulator often fails to allocate Neural Engine context for Revision 3 parsing.
                #if targetEnvironment(simulator)
                request.revision = VNDetectFaceRectanglesRequestRevision1
                #endif
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    print("Failed to perform face detection: \(error)")
                    lock.lock()
                    if !hasResumed {
                        hasResumed = true
                        lock.unlock()
                        #if targetEnvironment(simulator)
                        print("Simulator fallback: Ignoring handler exception and allowing upload.")
                        continuation.resume(returning: true)
                        #else
                        continuation.resume(returning: false)
                        #endif
                    } else {
                        lock.unlock()
                    }
                }
            }
        }
    }
}
