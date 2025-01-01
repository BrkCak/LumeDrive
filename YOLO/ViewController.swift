//  Ultralytics YOLO 🚀 - AGPL-3.0 License
//
//  Main View Controller for Ultralytics YOLO App
//  This file is part of the Ultralytics YOLO app, enabling real-time object detection using YOLOv8 models on iOS devices.
//  Licensed under AGPL-3.0. For commercial use, refer to Ultralytics licensing: https://ultralytics.com/license
//  Access the source code: https://github.com/ultralytics/yolo-ios-app
//
//  This ViewController manages the app's main screen, handling video capture, model selection, detection visualization,
//  and user interactions. It sets up and controls the video preview layer, handles model switching via a segmented control,
//  manages UI elements like sliders for confidence and IoU thresholds, and displays detection results on the video feed.
//  It leverages CoreML, Vision, and AVFoundation frameworks to perform real-time object detection and to interface with
//  the device's camera.

import AVFoundation
import CoreML
import CoreMedia
import UIKit
import Vision

var mlModel = try! yolov8m(configuration: .init()).model

class ViewController: UIViewController {
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
    var detector = try! VNCoreMLModel(for: mlModel)
    var session: AVCaptureSession!
    var videoCapture: VideoCapture!
    var currentBuffer: CVPixelBuffer?
    var framesDone = 0
    var t0 = 0.0  // inference start
    var t1 = 0.0  // inference dt
    var t2 = 0.0  // inference dt smoothed
    var t3 = CACurrentMediaTime()  // FPS start
    var t4 = 0.0  // FPS dt smoothed
    // var cameraOutput: AVCapturePhotoOutput!
    
    // Developer mode
    let developerMode = UserDefaults.standard.bool(forKey: "developer_mode")  // developer mode selected in settings
    let save_detections = false  // write every detection to detections.txt
    let save_frames = false  // write every frame to frames.txt
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.value = 30
        setLabels()
        setUpBoundingBoxViews()
        setUpOrientationChangeNotification()
        startVideo()
        // setModel()
    }
    
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
    
    /// Update thresholds from slider values
    @IBAction func sliderChanged(_ sender: Any) {
        let conf = Double(round(100 * sliderConf.value)) / 100
        let iou = Double(round(100 * sliderIoU.value)) / 100
        self.labelSliderConf.text = String(conf) + " Confidence Threshold"
        self.labelSliderIoU.text = String(iou) + " IoU Threshold"
        detector.featureProvider = ThresholdProvider(iouThreshold: iou, confidenceThreshold: conf)
        
    }
    
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
    
    let maxBoundingBoxViews = 100
    var boundingBoxViews = [BoundingBoxView]()
    var boundingBoxViewTaillightLeft: BoundingBoxView?
    var boundingBoxViewTaillightRight: BoundingBoxView?
    var taillightLeftViews: [BoundingBoxView] = []
    var taillightRightViews: [BoundingBoxView] = []
    let analyzer = BERAnalyzer()
    var carBoundingBoxViews: [BoundingBoxView] = []
    var colors: [String: UIColor] = [:]
    
    func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        
        // Retrieve class labels directly from the CoreML model's class labels, if available.
        guard let classLabels = mlModel.modelDescription.classLabels as? [String] else {
            fatalError("Class labels are missing from the model description")
        }
        
        // Assign random colors to the classes.
        for label in classLabels {
            if colors[label] == nil {  // if key not in dict
                colors[label] = UIColor(
                    red: CGFloat.random(in: 0...1),
                    green: CGFloat.random(in: 0...1),
                    blue: CGFloat.random(in: 0...1),
                    alpha: 0.6)
            }
        }
    }
    
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
    
    func show(predictions: [VNRecognizedObjectObservation]) {
        carBoundingBoxViews.removeAll()
        taillightLeftViews.forEach { $0.hide() }
        taillightRightViews.forEach { $0.hide() }
        taillightLeftViews.removeAll()
        taillightRightViews.removeAll()

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
            
            if bestClass == "car" && confidence > 0.6 {
                let label = String(format: "%@ %.1f", bestClass, confidence * 100)
                let alpha = CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9)

                boundingBoxViews[i].show(frame: rect, label: label, color: UIColor.systemGreen, alpha: alpha)
                carBoundingBoxViews.append(boundingBoxViews[i])

                detectAndShowTaillights(for: carBoundingBoxViews)
            } else {
                boundingBoxViews[i].hide()
            }
            /*
            //Test
            let label = String(format: "%@ %.1f", bestClass, confidence * 100)
            let alpha = CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9)
            boundingBoxViews[i].show(frame: rect, label: label, color: UIColor.systemGreen, alpha: alpha)
            carBoundingBoxViews.append(boundingBoxViews[i])
            detectAndShowTaillights(for: carBoundingBoxViews)
             //Test
            */
            if developerMode, save_detections {
                let detectionStr = String(format: "%.3f %.3f %.3f %@ %.2f %.1f %.1f %.1f %.1f\n",
                                          secDay, freeSpace(), UIDevice.current.batteryLevel,
                                          bestClass, confidence, rect.origin.x, rect.origin.y,
                                          rect.size.width, rect.size.height)
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
    
    var lastTaillightLeftImage: UIImage?
    var lastTaillightRightImage: UIImage?
    var buffer: [Int] = []
    func detectAndShowTaillights(for carViews: [BoundingBoxView]) {
        let differentialClassifier = DifferentialTaillightClassifier()
        
        for carBoundingBoxView in carViews {
            let detectTaillight = StaticTaillightDetector()
            let (tll, tlr) = detectTaillight.detectTaillights(frame: carBoundingBoxView.currentFrame)
            
            let taillightLeftView = BoundingBoxView()
            taillightLeftView.addToLayer(self.view.layer)
            taillightLeftView.show(frame: tll, label: "LeftTaillight", color: UIColor.blue, alpha: 0.8)
            taillightLeftViews.append(taillightLeftView)
            
            let taillightRightView = BoundingBoxView()
            taillightRightView.addToLayer(self.view.layer)
            taillightRightView.show(frame: tlr, label: "RightTaillight", color: UIColor.red, alpha: 0.8)
            taillightRightViews.append(taillightRightView)
            
            guard let currentFrameImage = captureCurrentFrameAsImage() else { continue }
            
            let taillightLeftImage = cropImage(to: tll, from: currentFrameImage)
            let taillightRightImage = cropImage(to: tlr, from: currentFrameImage)
            
            //Differential
            let isLeftActive = differentialClassifier.classifyTaillight(
                currentImage: taillightLeftImage,
                lastImage: lastTaillightLeftImage
            )
            if(isLeftActive) {
                taillightLeftView.show(frame: tll, label: "LeftTaillight", color: UIColor.purple, alpha: 0.8)
                buffer.append(1)
            } else {
                buffer.append(0)
            }
            
            let isRightActive = differentialClassifier.classifyTaillight(
                currentImage: taillightRightImage,
                lastImage: lastTaillightRightImage
            )
            if(isRightActive) {
                taillightRightView.show(frame: tlr, label: "RightTaillight", color: UIColor.purple, alpha: 0.8)
                buffer.append(1)
            } else {
                buffer.append(0)
            }
            //Differential
            
            lastTaillightLeftImage = taillightLeftImage
            lastTaillightRightImage = taillightRightImage
            taillightLeftViews.append(taillightLeftView)
            taillightRightViews.append(taillightRightView)
            
            if(buffer.count > 400) {
                let (_, _, _, berWithOffset) = analyzer.evalBER(for: buffer)
                print(berWithOffset)
                buffer.removeAll()
            }
        }
    }
    
    private func captureCurrentFrameAsImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func cropImage(to boundingBox: CGRect, from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        guard let croppedCGImage = cgImage.cropping(to: boundingBox) else { return nil }
        return UIImage(cgImage: croppedCGImage)
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

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
        predict(sampleBuffer: sampleBuffer)
    }
}

// Programmatically save image
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
