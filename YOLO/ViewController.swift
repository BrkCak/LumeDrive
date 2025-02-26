import AVFoundation
import CoreML
import CoreMedia
import UIKit
import Vision

/**
# ViewController
 
A `UIViewController` for real-time object and taillight recognition in video streams using CoreML, Vision, and AVFoundation.
 
## Overview
- Processes live video data from the device camera.
- Utilizes YOLOv8 models (n/s/m/l/x) for car detection.
- Analyzes taillights and turn signals using image processing and a BER (Bit Error Rate) analyzer.
- Provides UI controls for model parameters (confidence, IoU), zoom functionality, and data export.
 
## Key Components
- **CoreML**: Integration of YOLOv8 models for object detection.
- **Vision**: Handles pixel buffer processing and coordinate transformations.
- **AVFoundation**: Manages video capture, frame extraction, and presentation.
- **UI**: Dynamically adapts to device orientation, displays real-time stats (FPS, BER), and offers interactive controls.
 
## Notes
- Supports both portrait and landscape modes with orientation-specific UI elements.
- Developer mode enables saving detection data and frames for debugging.
*/

var mlModel = try! yolov8n(configuration: .init()).model

class ViewController: UIViewController {
    // MARK: - Properties

    @IBOutlet var videoPreview: UIView!
    @IBOutlet var View0: UIView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var playButtonOutlet: UIBarButtonItem!
    @IBOutlet var pauseButtonOutlet: UIBarButtonItem!
    @IBOutlet var slider: UISlider!
    @IBOutlet var sliderConf: UISlider!
    @IBOutlet weak var sliderConfLandScape: UISlider!
    @IBOutlet var sliderIoU: UISlider!
    @IBOutlet weak var sliderIoULandScape: UISlider!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelFPS: UILabel!
    @IBOutlet weak var labelBER: UILabel!
    @IBOutlet weak var labelZoom: UILabel!
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var labelSlider: UILabel!
    @IBOutlet weak var labelSliderConf: UILabel!
    @IBOutlet weak var labelSliderConfLandScape: UILabel!
    @IBOutlet weak var labelSliderIoU: UILabel!
    @IBOutlet weak var labelSliderIoULandScape: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var forcus: UIImageView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    let selection = UISelectionFeedbackGenerator()
    /// CoreML model for object detection (default: YOLOv8n).
    var detector = try! VNCoreMLModel(for: mlModel)
    var session: AVCaptureSession!
    /// Manages camera input and video capture session.
    var videoCapture: VideoCapture!
    /// Buffer for the current video frame being processed.
    var currentBuffer: CVPixelBuffer?
    /// Performance metrics (FPS, inference time).
    var t0 = 0.0  // inference start
    var t1 = 0.0  // inference dt
    var t2 = 0.0  // inference dt smoothed
    var t3 = CACurrentMediaTime()  // FPS start
    var t4 = 0.0  // FPS dt smoothed
    var currentImage: UIImage?

    let tailLightClassifier = DifferentialTaillightClassifier()
    let taillightDetector = StaticTaillightDetector()
    let leftTaillightBuffer = TaillightsRingBuffer()
    let rightTaillightBuffer = TaillightsRingBuffer()
    let analyzer = BERAnalyzer()
    lazy var berBuffer: BerRingBuffer = BerRingBuffer(capacity: analyzer.refBit.count, fileName: "BerBuffer.txt")
    var berUI = Double()
    var lastTimestamp: CMTime = .invalid
    var frameInterval = CMTime()
    var intervalSeconds = Double()
    var lastCarDetectionTime: CFTimeInterval?  // Timestamp for the last detected car
    
    // Developer mode
    let developerMode = UserDefaults.standard.bool(forKey: "developer_mode")  // developer mode selected in settings
    let save_detections = false  // write every detection to detections.txt
    let save_frames = false  // write every frame to frames.txt
    /// Vision request to handle CoreML predictions.
    lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(
            model: detector,
            completionHandler: {
                [weak self] request, error in
                self?.processObservations(for: request, error: error)
            })
        // NOTE: BoundingBoxView object scaling depends on request.imageCropAndScaleOption https://developer.apple.com/documentation/vision/vnimagecropandscaleoption
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
        return request
    }()
    // MARK: - Lifecycle

    /**
     Initializes UI, bounding box views, and starts video capture.
     - Sets default slider values.
     - Registers device orientation change notifications.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.value = 1
        setLabels()
        setUpBoundingBoxViews()
        setUpOrientationChangeNotification()
        startVideo()
        // setModel()
    }
    /**
     Adjusts UI layout during device orientation changes.
     - Parameter size: New view size.
     - Parameter coordinator: Transition coordinator.
     */
    override func viewWillTransition(
        to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if size.width > size.height {
            labelSliderConf.isHidden = true
            sliderConf.isHidden = true
            labelSliderIoU.isHidden = true
            sliderIoU.isHidden = true
            toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
            toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
            
            labelSliderConfLandScape.isHidden = false
            sliderConfLandScape.isHidden = false
            labelSliderIoULandScape.isHidden = false
            sliderIoULandScape.isHidden = false
            
        } else {
            labelSliderConf.isHidden = false
            sliderConf.isHidden = false
            labelSliderIoU.isHidden = false
            sliderIoU.isHidden = false
            toolBar.setBackgroundImage(nil, forToolbarPosition: .any, barMetrics: .default)
            toolBar.setShadowImage(nil, forToolbarPosition: .any)
            
            labelSliderConfLandScape.isHidden = true
            sliderConfLandScape.isHidden = true
            labelSliderIoULandScape.isHidden = true
            sliderIoULandScape.isHidden = true
        }
        self.videoCapture.previewLayer?.frame = CGRect(
            x: 0, y: 0, width: size.width, height: size.height)
        
    }
    
    private func setUpOrientationChangeNotification() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func orientationDidChange() {
        videoCapture.updateVideoOrientation()
    }
    
    @IBAction func vibrate(_ sender: Any) {
        selection.selectionChanged()
    }
    // MARK: - UI Interactions

    /**
     Switches the CoreML model based on the selected segment.
     - Parameter sender: Triggering segmented control.
     - Supported models: YOLOv8n, YOLOv8s, YOLOv8m, YOLOv8l, YOLOv8x.
     */
    @IBAction func indexChanged(_ sender: Any) {
        selection.selectionChanged()
        activityIndicator.startAnimating()
        
        /// Switch model
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            self.labelName.text = "YOLOv8n"
            mlModel = try! yolov8n(configuration: .init()).model
        case 1:
            self.labelName.text = "YOLOv8s"
            mlModel = try! yolov8s(configuration: .init()).model
        case 2:
            self.labelName.text = "YOLOv8m"
            mlModel = try! yolov8m(configuration: .init()).model
        case 3:
            self.labelName.text = "YOLOv8l"
            mlModel = try! yolov8l(configuration: .init()).model
        case 4:
            self.labelName.text = "YOLOv8x"
            mlModel = try! yolov8x(configuration: .init()).model
        default:
            break
        }
        setModel()
        setUpBoundingBoxViews()
        activityIndicator.stopAnimating()
    }
    
    func setModel() {
        
        /// VNCoreMLModel
        detector = try! VNCoreMLModel(for: mlModel)
        detector.featureProvider = ThresholdProvider()
        
        /// VNCoreMLRequest
        let request = VNCoreMLRequest(
            model: detector,
            completionHandler: { [weak self] request, error in
                self?.processObservations(for: request, error: error)
            })
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
        visionRequest = request
        t2 = 0.0  // inference dt smoothed
        t3 = CACurrentMediaTime()  // FPS start
        t4 = 0.0  // FPS dt smoothed
    }
    
    /**
     Updates confidence and IoU thresholds for object detection.
     - Parameter sender: Slider instance.
     */
    @IBAction func sliderChanged(_ sender: Any) {
        let conf = Double(round(100 * sliderConf.value)) / 100
        let iou = Double(round(100 * sliderIoU.value)) / 100
        self.labelSliderConf.text = String(conf) + " Confidence Threshold"
        self.labelSliderIoU.text = String(iou) + " IoU Threshold"
        detector.featureProvider = ThresholdProvider(iouThreshold: iou, confidenceThreshold: conf)
        
    }
    /// Updates UI labels with model metadata.
    func setLabels() {
        self.labelName.text = "YOLOv8m"
        self.labelVersion.text = "Version " + UserDefaults.standard.string(forKey: "app_version")!
    }
    
    @IBAction func playButton(_ sender: Any) {
        selection.selectionChanged()
        self.videoCapture.start()
        playButtonOutlet.isEnabled = false
        pauseButtonOutlet.isEnabled = true
    }
    
    @IBAction func pauseButton(_ sender: Any?) {
        selection.selectionChanged()
        self.videoCapture.stop()
        playButtonOutlet.isEnabled = true
        pauseButtonOutlet.isEnabled = false
    }
    
    // share image
    @IBAction func shareButton(_ sender: Any) {
        selection.selectionChanged()
        let settings = AVCapturePhotoSettings()
        self.videoCapture.cameraOutput.capturePhoto(
            with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    let maxBoundingBoxViews = 1
    var boundingBoxViews = [BoundingBoxView]()
    /// Initializes bounding box views for detection visualization.
    func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
    }
    // MARK: - Video Processing

    /**
     Starts video capture and configures preview layers.
     - Uses `AVCaptureSession` with `.photo` preset.
     - Adds bounding box layers to the UI.
     */
    func startVideo() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        
        videoCapture.setUp(sessionPreset: .photo) { success in
            // .hd4K3840x2160 or .photo (4032x3024)  Warning: 4k may not work on all devices i.e. 2019 iPod
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.videoCapture.previewLayer?.frame = self.videoPreview.bounds  // resize preview layer
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxViews {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    /**
     Processes a new video frame and initiates inference.
     - Parameter sampleBuffer: Captured frame as `CMSampleBuffer`.
     - Handles image orientation and executes Vision request.
     */
    func predict(sampleBuffer: CMSampleBuffer) {
        if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            currentBuffer = pixelBuffer
            
            /// - Tag: MappingOrientation
            // The frame is always oriented based on the camera sensor,
            // so in most cases Vision needs to rotate it for the model to work as expected.
            let imageOrientation: CGImagePropertyOrientation
            switch UIDevice.current.orientation {
            case .portrait:
                imageOrientation = .up
            case .portraitUpsideDown:
                imageOrientation = .down
            case .landscapeLeft:
                imageOrientation = .up
            case .landscapeRight:
                imageOrientation = .up
            case .unknown:
                imageOrientation = .up
            default:
                imageOrientation = .up
            }
            
            // Invoke a VNRequestHandler with that image
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
            if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
                t0 = CACurrentMediaTime()  // inference start
                do {
                    try handler.perform([visionRequest])
                } catch {
                    print(error)
                }
                t1 = CACurrentMediaTime() - t0  // inference dt
            }
            
            currentBuffer = nil
        }
    }
    /*
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.show(predictions: results)
            } else {
                self.show(predictions: [])
            }
            
            // Measure FPS
            if self.t1 < 10.0 {  // valid dt
                self.t2 = self.t1 * 0.05 + self.t2 * 0.95  // smoothed inference time
            }
            self.t4 = (CACurrentMediaTime() - self.t3) * 0.05 + self.t4 * 0.95  // smoothed delivered FPS
            self.labelFPS.text = String(format: "%.1f FPS - %.1f ms", 1 / self.t4, self.t2 * 1000)  // t2 seconds to ms
            self.t3 = CACurrentMediaTime()
        }
     }
 
     func processObservations(for request: VNRequest, error: Error?) {
     DispatchQueue.main.async {
     let carPredictions: [VNRecognizedObjectObservation]
     
     if let results = request.results as? [VNRecognizedObjectObservation] {
     carPredictions = results.filter { observation in
     guard let topLabel = observation.labels.first else { return false }
     return topLabel.identifier.lowercased() == "car" && topLabel.confidence > 0.5
     }
     } else {
     carPredictions = []
     }
     
     self.show(predictions: carPredictions)
     
     // Zeitmessung zwischen Auto-Erkennungen
     if !carPredictions.isEmpty { // Falls mindestens ein Auto erkannt wurde
     let currentTime = CACurrentMediaTime()
     if let lastTime = self.lastCarDetectionTime {
     let timeDifference = currentTime - lastTime
     appendIntervalToFile(timeDifference*1000, berValue: self.berUI)
     }
     self.lastCarDetectionTime = currentTime
     }
     
     // FPS-Berechnung (beibehalten)
     if self.t1 < 10.0 {
     self.t2 = self.t1 * 0.05 + self.t2 * 0.95
     }
     self.t4 = (CACurrentMediaTime() - self.t3) * 0.05 + self.t4 * 0.95
     self.labelFPS.text = String(format: "%.1f FPS - %.1f ms", 1 / self.t4, self.t2 * 1000)
     self.t3 = CACurrentMediaTime()
     }
     }
     */
    // MARK: - Object Detection

    /**
     Processes Vision request results.
     - Filters "car" detections and updates UI.
     - Calculates FPS and performance metrics.
     - Parameter request: Vision request containing results.
     - Parameter error: Optional processing error.
     */
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            let carPredictions: [VNRecognizedObjectObservation]
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                // Filtere nur Objekte mit dem Label "car"
                carPredictions = results.filter { observation in
                    // Prüfe das Top-Label mit höchster Confidence
                    guard let topLabel = observation.labels.first else { return false }
                    return topLabel.identifier.lowercased() == "car" // Anpassung je nach Modell-Label
                }
            } else {
                carPredictions = []
            }
            self.show(predictions: carPredictions)
            
            if self.t1 < 10.0 {
                self.t2 = self.t1 * 0.05 + self.t2 * 0.95
            }
            self.t4 = (CACurrentMediaTime() - self.t3) * 0.05 + self.t4 * 0.95
            self.labelFPS.text = String(format: "%.1f FPS - %.1f ms", 1 / self.t4, self.t2 * 1000)
            self.t3 = CACurrentMediaTime()
        }
    }

    // Save text file
    func saveText(text: String, file: String = "saved.txt") {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            
            // Writing
            do {  // Append to file if it exists
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(text.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {  // Create new file and write
                do {
                    try text.write(to: fileURL, atomically: false, encoding: .utf8)
                } catch {
                    print("no file written")
                }
            }
            
            // Reading
            // do {let text2 = try String(contentsOf: fileURL, encoding: .utf8)} catch {/* error handling here */}
        }
    }
    
    // Return hard drive space (GB)
    func freeSpace() -> Double {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey
            ])
            return Double(values.volumeAvailableCapacityForImportantUsage!) / 1E9  // Bytes to GB
        } catch {
            print("Error retrieving storage capacity: \(error.localizedDescription)")
        }
        return 0
    }
    
    // Return RAM usage (GB)
    func memoryUsage() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return Double(taskInfo.resident_size) / 1E9  // Bytes to GB
        } else {
            return 0
        }
    }
    /**
     Displays detected objects as bounding boxes.
     - Transforms normalized coordinates to screen space.
     - Analyzes taillights and saves debug data (if enabled).
     - Parameter predictions: Array of detected objects (`VNRecognizedObjectObservation`).
     */
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = videoPreview.bounds.width
        let height = videoPreview.bounds.height

        let ratio: CGFloat = {
            let presetAR = (videoCapture.captureSession.sessionPreset == .photo) ? (4.0 / 3.0) : (16.0 / 9.0)
            return (height / width) / presetAR
        }()

        let date = Date()
        let calendar = Calendar.current
        let secDay = Double(calendar.component(.hour, from: date)) * 3600.0 +
                     Double(calendar.component(.minute, from: date)) * 60.0 +
                     Double(calendar.component(.second, from: date)) +
                     Double(calendar.component(.nanosecond, from: date)) / 1E9

        labelSlider.text = "\(predictions.count) items (max \(Int(slider.value)))"
        
        for i in 0..<boundingBoxViews.count where i < predictions.count && i < Int(slider.value) {
            let prediction = predictions[i]
            var rect = prediction.boundingBox
            rect = adjustBoundingBox(rect: rect)
            rect = transformBoundingBox(rect: rect, width: width, height: height, ratio: ratio)
            
            let bestClass = prediction.labels[0].identifier
            let confidence = prediction.labels[0].confidence
            
            if let currentImage = currentImage {
                let label = String(format: "%@ %.1f", bestClass, confidence * 100)
                let alpha = CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9)
                boundingBoxViews[i].show(frame: rect, label: label, color: UIColor.systemGreen, alpha: alpha)
                
                let imageWidth = currentImage.size.width
                let imageHeight = currentImage.size.height
                
                let originalRect = prediction.boundingBox
                let x = originalRect.origin.x * imageWidth
                let y = (1 - originalRect.origin.y - originalRect.height) * imageHeight
                let cropWidth = originalRect.width * imageWidth
                let cropHeight = originalRect.height * imageHeight
                
                let safeX = max(0, min(x, imageWidth - 1))
                let safeY = max(0, min(y, imageHeight - 1))
                let safeWidth = max(1, min(cropWidth, imageWidth - safeX))
                let safeHeight = max(1, min(cropHeight, imageHeight - safeY))
                
                let cropRect = CGRect(x: safeX, y: safeY, width: safeWidth, height: safeHeight)
                let (tll, tlr) = taillightDetector.positionTaillights(frame: cropRect)
                
                if (taillightDetector.cropImage(from: currentImage, to: cropRect) != nil),
                   let croppedLeftTailLight = taillightDetector.cropImage(from: currentImage, to: tll),
                   let croppedRightTailLight = taillightDetector.cropImage(from: currentImage, to: tlr) {
                    //saveImageToPhotos(image: croppedImage, frameNumber: frameCount)
                    leftTaillightBuffer.addImage(croppedLeftTailLight)
                    //leftTaillightBuffer.saveBufferToDisk(name: "leftTaillightBuffer")
                    rightTaillightBuffer.addImage(croppedRightTailLight)
                    //rightTaillightBuffer.saveBufferToDisk(name: "rightTaillightBuffer")
                } else {
                    print("⚠️ Fehler beim Erstellen des Bildausschnitts!")
                    print("📸 Originalbild: \(currentImage)")
                    print("🔍 Ausschnitt-Rect: \(cropRect)")
                }
                tailLightClassifier.tailLightDetectionLoop(carBoundingBoxView: boundingBoxViews[i], videoPreview: videoPreview)
                tailLightClassifier.classifyTaillights(leftTailLightBuffer: leftTaillightBuffer, rightTailLightBuffer: rightTaillightBuffer, berBuffer: berBuffer)
                
            }
            
            if (berBuffer.isFull) {
                berUI = analyzer.evalBER(for: berBuffer.getBuffer()) ?? 0.0
                labelBER.text = String(format: " BER: %.2f%%", berUI)
            }
            
            if developerMode, save_detections {
                let detectionStr = String(format: "%.3f %.3f %.3f %@ %.2f\n",
                                          secDay, freeSpace(), UIDevice.current.batteryLevel,
                                          bestClass, confidence)
                saveText(text: detectionStr, file: "detections.txt")
            }
        }
        if developerMode, save_frames {
            let frameStats = String(format: "%.3f %.3f %.3f %.3f %.1f %.1f %.1f\n",
                                    secDay, freeSpace(), memoryUsage(), UIDevice.current.batteryLevel,
                                    t1 * 1000, t2 * 1000, 1 / t4)
            saveText(text: frameStats, file: "frames.txt")
        }
    }
    
    ///for debugging to see which pictures are incoming
    func saveImageToPhotos(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    func saveImageToPhotos(image: UIImage, frameNumber: Int) {
        let text = "Frame \(frameNumber)"
        let font = UIFont.boldSystemFont(ofSize: 40)
        let textColor = UIColor.red
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .backgroundColor: UIColor.clear
        ]
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        let textRect = CGRect(x: 20, y: 20, width: image.size.width - 40, height: 50)
        text.draw(in: textRect, withAttributes: textAttributes)
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let annotatedImage = annotatedImage {
            UIImageWriteToSavedPhotosAlbum(annotatedImage, nil, nil, nil)
        } else {
            print("Fehler: Annotiertes Bild konnte nicht erstellt werden.")
        }
    }


    func adjustBoundingBox(rect: CGRect) -> CGRect {
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            return CGRect(x: 1.0 - rect.origin.x - rect.width,
                          y: 1.0 - rect.origin.y - rect.height,
                          width: rect.width, height: rect.height)
        case .landscapeLeft, .landscapeRight:
            return rect
        case .unknown:
            print("Die Geräteausrichtung ist unbekannt, die Vorhersagen könnten beeinträchtigt sein")
            fallthrough
        default:
            return rect
        }
    }
    func transformBoundingBox(rect: CGRect, width: CGFloat, height: CGFloat, ratio: CGFloat) -> CGRect {
        var transformedRect = rect

        if ratio >= 1 {
            let offset = (1 - ratio) * (0.5 - rect.minX)
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: offset, y: -1)
            transformedRect = rect.applying(transform)
            transformedRect.size.width *= ratio
        } else {
            let offset = (ratio - 1) * (0.5 - rect.maxY)
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: offset - 1)
            transformedRect = rect.applying(transform)
            transformedRect.size.height /= ratio
        }

        return VNImageRectForNormalizedRect(transformedRect, Int(width), Int(height))
    }
    
    // Pinch to Zoom Start ---------------------------------------------------------------------------------------------
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 10.0
    var lastZoomFactor: CGFloat = 1.0
    
    @IBAction func pinch(_ pinch: UIPinchGestureRecognizer) {
        let device = videoCapture.captureDevice
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer {
                    device.unlockForConfiguration()
                }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        switch pinch.state {
        case .began, .changed:
            update(scale: newScaleFactor)
            self.labelZoom.text = String(format: "%.2fx", newScaleFactor)
            self.labelZoom.font = UIFont.preferredFont(forTextStyle: .title2)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
            self.labelZoom.font = UIFont.preferredFont(forTextStyle: .body)
        default: break
        }
    }  // Pinch to Zoom End --------------------------------------------------------------------------------------------
}  // ViewController class End
// MARK: - VideoCaptureDelegate Extension

/**
 Handles video frame capture events.
 - Extracts frames and forwards them for inference.
 - Measures frame intervals for BER calculations.
 */
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let previousTimestamp = lastTimestamp
        lastTimestamp = timestamp
        if previousTimestamp.isValid && berBuffer.isFull {
            frameInterval = CMTimeSubtract(timestamp, previousTimestamp)
            intervalSeconds = CMTimeGetSeconds(frameInterval) * 1000
            berBuffer.saveBufferToFile(berValue: berUI, interval: intervalSeconds)
        }
        
        currentImage = UIImage(sampleBuffer: sampleBuffer)
        predict(sampleBuffer: sampleBuffer)
    }
}

func appendIntervalToFile(_ interval: Double, berValue: Double) {
    let fileName = "frameIntervals.txt"
    if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        let text = "Frame interval: \(interval)ms | BER: \(berValue)%%\n"
        
        if let data = text.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let fileHandle = try FileHandle(forWritingTo: fileURL)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } catch {
                    print("Fehler beim Schreiben in die Datei: \(error)")
                }
            } else {
                do {
                    try text.write(to: fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("Fehler beim Erstellen der Datei: \(error)")
                }
            }
        }
    }
}

extension UIImage {
    convenience init?(sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    self.init(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}
// MARK: - AVCapturePhotoCaptureDelegate Extension

/**
 Manages photo capture and sharing.
 - Exports screenshots with overlay data (bounding boxes, stats).
 */
extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?
    ) {
        if let error = error {
            print("error occurred : \(error.localizedDescription)")
        }
        if let dataImage = photo.fileDataRepresentation() {
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(
                jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true,
                intent: .defaultIntent)
            var orientation = CGImagePropertyOrientation.right
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                orientation = .up
            case .landscapeRight:
                orientation = .down
            default:
                break
            }
            var image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: .right)
            if let orientedCIImage = CIImage(image: image)?.oriented(orientation),
               let cgImage = CIContext().createCGImage(orientedCIImage, from: orientedCIImage.extent)
            {
                image = UIImage(cgImage: cgImage)
            }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.frame = videoPreview.frame
            let imageLayer = imageView.layer
            videoPreview.layer.insertSublayer(imageLayer, above: videoCapture.previewLayer)
            
            let bounds = UIScreen.main.bounds
            UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
            self.View0.drawHierarchy(in: bounds, afterScreenUpdates: true)
            let img = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            imageLayer.removeFromSuperlayer()
            let activityViewController = UIActivityViewController(
                activityItems: [img!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.View0
            self.present(activityViewController, animated: true, completion: nil)
            //
            //            // Save to camera roll
            //            UIImageWriteToSavedPhotosAlbum(img!, nil, nil, nil);
        } else {
            print("AVCapturePhotoCaptureDelegate Error")
        }
    }
}
