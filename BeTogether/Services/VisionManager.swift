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
                        continuation.resume(returning: false)
                        return
                    }
                    let results = request.results as? [VNFaceObservation] ?? []
                    continuation.resume(returning: results.count == 1)
                }
                
                // Fix for iOS Simulator "Could not create inference context" error
                #if targetEnvironment(simulator)
                if #available(iOS 17.0, *) {
                    // usesCPUOnly is deprecated in iOS 17+ and the bug is largely fixed
                } else {
                    // Suppress iOS 17 deprecation warning while retaining the simulator fix for iOS 16 fallback testing
                    request.perform( #selector(setter: VNDetectFaceRectanglesRequest.usesCPUOnly), with: true)
                }
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
                        continuation.resume(returning: false)
                    } else {
                        lock.unlock()
                    }
                }
            }
        }
    }
}
