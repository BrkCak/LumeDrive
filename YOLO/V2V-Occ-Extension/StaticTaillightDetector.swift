import Foundation
import UIKit
/**
 * The `StaticTaillightDetector` class detects the position of taillights in a given image frame and allows cropping an image accordingly.
 */
class StaticTaillightDetector {
    /**
     * Calculates the positions of both taillights within a given frame.
     *
     * @param frame The overall frame in which the taillights are located.
     * @return A tuple of two CGRect values:
     *         - The first CGRect represents the left taillight.
     *         - The second CGRect represents the right taillight.
     */
    func positionTaillights(frame: CGRect) -> (CGRect, CGRect) {
        let top = frame.origin.y
        let left = frame.origin.x
        let width = frame.width
        let height = frame.height
        let right = left + width
        
        let tlTop = top + height / 4
        let tlBottom = top + 7 * height / 12
        
        let tllLeft = left
        let tllRight = left + 5 * width / 16
        
        let tlrLeft = right - 5 * width / 16
        let tlrRight = right
        
        let tll = CGRect(
            x: Int(tllLeft),
            y: Int(tlTop),
            width: Int(tllRight - tllLeft),
            height: Int(tlBottom - tlTop)
        )
        
        let tlr = CGRect(
            x: Int(tlrLeft),
            y: Int(tlTop),
            width: Int(tlrRight - tlrLeft),
            height: Int(tlBottom - tlTop)
        )
        
        return (tll, tlr)
    }
    /**
     * Crops a specific region from a given image.
     *
     * @param image The original image.
     * @param rect The region to be cropped from the image.
     * @return The cropped image or `nil` if an error occurs.
     */
    func cropImage(from image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else {
            print("Fehler: Bild konnte nicht in CGImage konvertiert werden.")
            return nil
        }
        
        guard let croppedCGImage = cgImage.cropping(to: rect) else {
            print("Fehler: Bild konnte nicht ausgeschnitten werden.")
            return nil
        }
        
        let croppedImage = UIImage(cgImage: croppedCGImage)
        return croppedImage
    }
}
