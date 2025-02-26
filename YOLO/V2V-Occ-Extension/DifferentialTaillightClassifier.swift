import UIKit

/**
# DifferentialTaillightClassifier

A classifier for detecting and analyzing vehicle taillight states using differential image comparison.

## Overview
- Detects left/right taillight activity by comparing sequential image frames
- Visualizes detection results with dynamic bounding boxes
- Logs Bit Error Rate (BER) data for signal analysis
- Works in conjunction with `TaillightsRingBuffer` and `BerRingBuffer` for data management

## Key Features
- Differential analysis between current and previous taillight states
- Real-time visualization of active taillights
- Persistent BER logging for signal quality monitoring
*/

class DifferentialTaillightClassifier {
    // MARK: - Properties

    /// Wrapper for left taillight classification logic
    let leftTailLightWrapper: DifferentialTaillightClassifierWrapper
    /// Wrapper for right taillight classification logic
    let rightTailLightWrapper: DifferentialTaillightClassifierWrapper
    /// Detector for static taillight positions
    private let tailLightPositionBox = StaticTaillightDetector()
    /// Bounding box visualization for left taillight
    private let tailLightLeftBoundaryBox = BoundingBoxView()
    /// Bounding box visualization for right taillight
    private let tailLightRightBoundaryBox = BoundingBoxView()
    /// Buffer for BER values during classification
    var berArray: [Int] = []
    /// Counter for BER array indexing
    var berArrayCounter = 0
    private var tll = CGRect()
    private var tlr = CGRect()
    // MARK: - Initialization

    /**
     Initializes classifier with left/right differentiation capabilities
     - Creates separate wrappers for each side with identifiers
     */
    init() {
        self.leftTailLightWrapper = DifferentialTaillightClassifierWrapper()
        self.leftTailLightWrapper.sideIdentifier = "Left"
        self.rightTailLightWrapper = DifferentialTaillightClassifierWrapper()
        self.rightTailLightWrapper.sideIdentifier = "Right"
    }
    // MARK: - Detection Methods
    
    /**
     Manages taillight detection visualization loop
     - Parameters:
        - carBoundingBoxView: Main vehicle bounding box reference
        - videoPreview: Layer for visualization overlay
     - Calculates taillight positions relative to vehicle bounding box
     - Updates bounding box displays in preview layer
     */
    func tailLightDetectionLoop(carBoundingBoxView: BoundingBoxView, videoPreview: UIView) {
        tailLightLeftBoundaryBox.hide()
        tailLightRightBoundaryBox.hide()
        
        (tll, tlr) = tailLightPositionBox.positionTaillights(frame: carBoundingBoxView.currentFrame)
        
        tailLightLeftBoundaryBox.addToLayer(videoPreview.layer)
        tailLightLeftBoundaryBox.show(frame: tll, label: "LeftTaillight", color: UIColor.blue, alpha: 0.8)
        
        tailLightRightBoundaryBox.addToLayer(videoPreview.layer)
        tailLightRightBoundaryBox.show(frame: tlr, label: "RightTaillight", color: UIColor.red, alpha: 0.8)
    }
    // MARK: - Classification Methods
    
    /**
     Classifies taillight states using differential analysis
     - Parameters:
        - leftTailLightBuffer: Image buffer for left taillight
        - rightTailLightBuffer: Image buffer for right taillight
        - berBuffer: BER data storage for signal analysis
     - Processes most recent images from both taillight buffers
     - Updates BER buffer with classification results
     - Highlights active taillights with purple bounding boxes
     */
    func classifyTaillights(leftTailLightBuffer: TaillightsRingBuffer, rightTailLightBuffer: TaillightsRingBuffer, berBuffer: BerRingBuffer) {
        /// classify first the left taillight
        if let leftCurrentImage = leftTailLightBuffer.getLastImage(),
           let leftLastImage = leftTailLightBuffer.getFirstImage() {
            
            let leftTailLightState = leftTailLightWrapper.classifyTaillight(
                leftCurrentImage,
                last: leftLastImage
            )
            
            //berArray.append(leftTailLightState ? 1 : 0)
            //saveBerArrayToFile()
            
            berBuffer.append(leftTailLightState ? 1 : 0)
            if(leftTailLightState) {
                tailLightLeftBoundaryBox.show(frame: tll, label: "LeftTaillight", color: UIColor.purple, alpha: 0.8)
            }
         }
        
        /// classify right taillight
        if let rightCurrentImage = rightTailLightBuffer.getLastImage(),
           let rightLastImage = rightTailLightBuffer.getFirstImage() {
            
            let rightTailLightState = rightTailLightWrapper.classifyTaillight(
                rightCurrentImage,
                last: rightLastImage
            )
            
            //berArray.append(rightTailLightState ? 1 : 0)
            //saveBerArrayToFile()
            
            berBuffer.append(rightTailLightState ? 1 : 0)
            if(rightTailLightState) {
                tailLightRightBoundaryBox.show(frame: tlr, label: "RightTaillight", color: UIColor.purple, alpha: 0.8)
            }
         }
    }
    // MARK: - Data Logging
    
    /**
     Appends new BER values to persistent storage
     - Writes single-bit entries to "berLog.txt" in documents directory
     - Uses incremental counter to track array position
     - Handles file creation and appending operations
     */
    func saveBerArrayToFile() {
        guard berArrayCounter < berArray.count else { return }
        
        let newBit = berArray[berArrayCounter]
        let formattedString = String(newBit)
        
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("berLog.txt")
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(formattedString.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try formattedString.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("⚠️ Fehler: \(error.localizedDescription)")
        }
        berArrayCounter += 1
    }
}
