import Foundation
import UIKit

class StaticTaillightDetector {
    func detectTaillights(frame: CGRect) -> (CGRect, CGRect) {
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
}
