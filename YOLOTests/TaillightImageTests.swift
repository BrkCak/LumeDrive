import XCTest
@testable import YOLO

class TaillightImageTests: XCTestCase {
    let taillightImage = StaticTaillightDetector()
    
    func testTaillightPosition() {
        let bundle = Bundle(for: type(of: self))
        
        guard let path1 = bundle.path(forResource: "frame_0000", ofType: "png"),
              let path2 = bundle.path(forResource: "frame_0001", ofType: "png"),
              let path3 = bundle.path(forResource: "frame_0002", ofType: "png"),
              let path4 = bundle.path(forResource: "frame_0003", ofType: "png"),
              let path5 = bundle.path(forResource: "frame_0004", ofType: "png"),
              let path6 = bundle.path(forResource: "frame_0005", ofType: "png"),
              let path7 = bundle.path(forResource: "frame_0006", ofType: "png"),
              let path8 = bundle.path(forResource: "frame_0007", ofType: "png"),
              let path9 = bundle.path(forResource: "frame_0008", ofType: "png"),
              let path10 = bundle.path(forResource: "frame_0009", ofType: "png"),
              let path11 = bundle.path(forResource: "frame_0010", ofType: "png"),
              let path12 = bundle.path(forResource: "frame_0011", ofType: "png"),
              let path13 = bundle.path(forResource: "frame_0012", ofType: "png"),
              let path14 = bundle.path(forResource: "frame_0013", ofType: "png"),
              let path15 = bundle.path(forResource: "frame_0014", ofType: "png"),
              let path16 = bundle.path(forResource: "frame_0015", ofType: "png"),
              let path17 = bundle.path(forResource: "frame_0016", ofType: "png"),
              let path18 = bundle.path(forResource: "frame_0017", ofType: "png"),
              let path19 = bundle.path(forResource: "frame_0018", ofType: "png"),
              let path20 = bundle.path(forResource: "frame_0019", ofType: "png"),
              let path21 = bundle.path(forResource: "frame_0020", ofType: "png"),
              let path22 = bundle.path(forResource: "frame_0021", ofType: "png"),
              let path23 = bundle.path(forResource: "frame_0022", ofType: "png"),
              let path24 = bundle.path(forResource: "frame_0023", ofType: "png"),
              let path25 = bundle.path(forResource: "frame_0024", ofType: "png"),
              let path26 = bundle.path(forResource: "frame_0025", ofType: "png"),
              let path27 = bundle.path(forResource: "frame_0026", ofType: "png"),
              let path28 = bundle.path(forResource: "frame_0027", ofType: "png"),
              let path29 = bundle.path(forResource: "frame_0028", ofType: "png"),
              let path30 = bundle.path(forResource: "frame_0029", ofType: "png"),
              let path31 = bundle.path(forResource: "frame_0030", ofType: "png"),
              let path32 = bundle.path(forResource: "frame_0031", ofType: "png")
        else {
            XCTFail("Bilder konnten nicht gefunden werden")
            return
        }
        guard let image1 = UIImage(contentsOfFile: path1),
              let image2 = UIImage(contentsOfFile: path2),
              let image3 = UIImage(contentsOfFile: path3),
              let image4 = UIImage(contentsOfFile: path4),
              let image5 = UIImage(contentsOfFile: path5),
              let image6 = UIImage(contentsOfFile: path6),
              let image7 = UIImage(contentsOfFile: path7),
              let image8 = UIImage(contentsOfFile: path8),
              let image9 = UIImage(contentsOfFile: path9),
              let image10 = UIImage(contentsOfFile: path10),
              let image11 = UIImage(contentsOfFile: path11),
              let image12 = UIImage(contentsOfFile: path12),
              let image13 = UIImage(contentsOfFile: path13),
              let image14 = UIImage(contentsOfFile: path14),
              let image15 = UIImage(contentsOfFile: path15),
              let image16 = UIImage(contentsOfFile: path16),
              let image17 = UIImage(contentsOfFile: path17),
              let image18 = UIImage(contentsOfFile: path18),
              let image19 = UIImage(contentsOfFile: path19),
              let image20 = UIImage(contentsOfFile: path20),
              let image21 = UIImage(contentsOfFile: path21),
              let image22 = UIImage(contentsOfFile: path22),
              let image23 = UIImage(contentsOfFile: path23),
              let image24 = UIImage(contentsOfFile: path24),
              let image25 = UIImage(contentsOfFile: path25),
              let image26 = UIImage(contentsOfFile: path26),
              let image27 = UIImage(contentsOfFile: path27),
              let image28 = UIImage(contentsOfFile: path28),
              let image29 = UIImage(contentsOfFile: path29),
              let image30 = UIImage(contentsOfFile: path30),
              let image31 = UIImage(contentsOfFile: path31),
              let image32 = UIImage(contentsOfFile: path32)
        else {
            XCTFail("Bilder konnten nicht geladen werden")
            return
        }
        
        let image1Rect = CGRect(x: 0, y: 0, width: image1.size.width, height: image1.size.height)
        let (tll1, tlr1) = StaticTaillightDetector().positionTaillights(frame: image1Rect)
        saveTaillightImages(from: image1, tll: tll1, tlr: tlr1, savePath: "FirstCar")
        let image2Rect = CGRect(x: 0, y: 0, width: image2.size.width, height: image2.size.height)
        let (tll2, tlr2) = StaticTaillightDetector().positionTaillights(frame: image2Rect)
        saveTaillightImages(from: image2, tll: tll2, tlr: tlr2, savePath: "SecondCar")
        let image3Rect = CGRect(x: 0, y: 0, width: image3.size.width, height: image3.size.height)
        let (tll3, tlr3) = StaticTaillightDetector().positionTaillights(frame: image3Rect)
        saveTaillightImages(from: image3, tll: tll3, tlr: tlr3, savePath: "ThirdCar")
        let image4Rect = CGRect(x: 0, y: 0, width: image4.size.width, height: image4.size.height)
        let (tll4, tlr4) = StaticTaillightDetector().positionTaillights(frame: image4Rect)
        saveTaillightImages(from: image4, tll: tll4, tlr: tlr4, savePath: "FourthCar")
        let image5Rect = CGRect(x: 0, y: 0, width: image5.size.width, height: image5.size.height)
        let (tll5, tlr5) = StaticTaillightDetector().positionTaillights(frame: image5Rect)
        saveTaillightImages(from: image5, tll: tll5, tlr: tlr5, savePath: "FifthCar")
        let image6Rect = CGRect(x: 0, y: 0, width: image6.size.width, height: image6.size.height)
        let (tll6, tlr6) = StaticTaillightDetector().positionTaillights(frame: image6Rect)
        saveTaillightImages(from: image6, tll: tll6, tlr: tlr6, savePath: "SixthCar")
        let image7Rect = CGRect(x: 0, y: 0, width: image7.size.width, height: image7.size.height)
        let (tll7, tlr7) = StaticTaillightDetector().positionTaillights(frame: image7Rect)
        saveTaillightImages(from: image7, tll: tll7, tlr: tlr7, savePath: "SeventhCar")
        let image8Rect = CGRect(x: 0, y: 0, width: image8.size.width, height: image8.size.height)
        let (tll8, tlr8) = StaticTaillightDetector().positionTaillights(frame: image8Rect)
        saveTaillightImages(from: image8, tll: tll8, tlr: tlr8, savePath: "EighthCar")
        let image9Rect = CGRect(x: 0, y: 0, width: image9.size.width, height: image9.size.height)
        let (tll9, tlr9) = StaticTaillightDetector().positionTaillights(frame: image9Rect)
        saveTaillightImages(from: image9, tll: tll9, tlr: tlr9, savePath: "NinthCar")
        let image10Rect = CGRect(x: 0, y: 0, width: image10.size.width, height: image10.size.height)
        let (tll10, tlr10) = StaticTaillightDetector().positionTaillights(frame: image10Rect)
        saveTaillightImages(from: image10, tll: tll10, tlr: tlr10, savePath: "TenthCar")
        let image11Rect = CGRect(x: 0, y: 0, width: image11.size.width, height: image11.size.height)
        let (tll11, tlr11) = StaticTaillightDetector().positionTaillights(frame: image11Rect)
        saveTaillightImages(from: image11, tll: tll11, tlr: tlr11, savePath: "EleventhCar")
        let image12Rect = CGRect(x: 0, y: 0, width: image12.size.width, height: image12.size.height)
        let (tll12, tlr12) = StaticTaillightDetector().positionTaillights(frame: image12Rect)
        saveTaillightImages(from: image12, tll: tll12, tlr: tlr12, savePath: "TwelfthCar")
        let image13Rect = CGRect(x: 0, y: 0, width: image13.size.width, height: image13.size.height)
        let (tll13, tlr13) = StaticTaillightDetector().positionTaillights(frame: image13Rect)
        saveTaillightImages(from: image13, tll: tll13, tlr: tlr13, savePath: "ThirteenthCar")
        let image14Rect = CGRect(x: 0, y: 0, width: image14.size.width, height: image14.size.height)
        let (tll14, tlr14) = StaticTaillightDetector().positionTaillights(frame: image14Rect)
        saveTaillightImages(from: image14, tll: tll14, tlr: tlr14, savePath: "FourteenthCar")
        let image15Rect = CGRect(x: 0, y: 0, width: image15.size.width, height: image15.size.height)
        let (tll15, tlr15) = StaticTaillightDetector().positionTaillights(frame: image15Rect)
        saveTaillightImages(from: image15, tll: tll15, tlr: tlr15, savePath: "FifteenthCar")
        let image16Rect = CGRect(x: 0, y: 0, width: image16.size.width, height: image16.size.height)
        let (tll16, tlr16) = StaticTaillightDetector().positionTaillights(frame: image16Rect)
        saveTaillightImages(from: image16, tll: tll16, tlr: tlr16, savePath: "SixteenthCar")
        let image17Rect = CGRect(x: 0, y: 0, width: image17.size.width, height: image17.size.height)
        let (tll17, tlr17) = StaticTaillightDetector().positionTaillights(frame: image17Rect)
        saveTaillightImages(from: image17, tll: tll17, tlr: tlr17, savePath: "SeventeenthCar")
        let image18Rect = CGRect(x: 0, y: 0, width: image18.size.width, height: image18.size.height)
        let (tll18, tlr18) = StaticTaillightDetector().positionTaillights(frame: image18Rect)
        saveTaillightImages(from: image18, tll: tll18, tlr: tlr18, savePath: "EighteenthCar")
        let image19Rect = CGRect(x: 0, y: 0, width: image19.size.width, height: image19.size.height)
        let (tll19, tlr19) = StaticTaillightDetector().positionTaillights(frame: image19Rect)
        saveTaillightImages(from: image19, tll: tll19, tlr: tlr19, savePath: "NineteenthCar")
        let image20Rect = CGRect(x: 0, y: 0, width: image20.size.width, height: image20.size.height)
        let (tll20, tlr20) = StaticTaillightDetector().positionTaillights(frame: image20Rect)
        saveTaillightImages(from: image20, tll: tll20, tlr: tlr20, savePath: "TwentiethCar")
        let image21Rect = CGRect(x: 0, y: 0, width: image21.size.width, height: image21.size.height)
        let (tll21, tlr21) = StaticTaillightDetector().positionTaillights(frame: image21Rect)
        saveTaillightImages(from: image21, tll: tll21, tlr: tlr21, savePath: "TwentyFirstCar")
        let image22Rect = CGRect(x: 0, y: 0, width: image22.size.width, height: image22.size.height)
        let (tll22, tlr22) = StaticTaillightDetector().positionTaillights(frame: image22Rect)
        saveTaillightImages(from: image22, tll: tll22, tlr: tlr22, savePath: "TwentySecondCar")
        let image23Rect = CGRect(x: 0, y: 0, width: image23.size.width, height: image23.size.height)
        let (tll23, tlr23) = StaticTaillightDetector().positionTaillights(frame: image23Rect)
        saveTaillightImages(from: image23, tll: tll23, tlr: tlr23, savePath: "TwentyThirdCar")
        let image24Rect = CGRect(x: 0, y: 0, width: image24.size.width, height: image24.size.height)
        let (tll24, tlr24) = StaticTaillightDetector().positionTaillights(frame: image24Rect)
        saveTaillightImages(from: image24, tll: tll24, tlr: tlr24, savePath: "TwentyFourthCar")
        let image25Rect = CGRect(x: 0, y: 0, width: image25.size.width, height: image25.size.height)
        let (tll25, tlr25) = StaticTaillightDetector().positionTaillights(frame: image25Rect)
        saveTaillightImages(from: image25, tll: tll25, tlr: tlr25, savePath: "TwentyFifthCar")
        let image26Rect = CGRect(x: 0, y: 0, width: image26.size.width, height: image26.size.height)
        let (tll26, tlr26) = StaticTaillightDetector().positionTaillights(frame: image26Rect)
        saveTaillightImages(from: image26, tll: tll26, tlr: tlr26, savePath: "TwentySixthCar")
        let image27Rect = CGRect(x: 0, y: 0, width: image27.size.width, height: image27.size.height)
        let (tll27, tlr27) = StaticTaillightDetector().positionTaillights(frame: image27Rect)
        saveTaillightImages(from: image27, tll: tll27, tlr: tlr27, savePath: "TwentySeventhCar")
        let image28Rect = CGRect(x: 0, y: 0, width: image28.size.width, height: image28.size.height)
        let (tll28, tlr28) = StaticTaillightDetector().positionTaillights(frame: image28Rect)
        saveTaillightImages(from: image28, tll: tll28, tlr: tlr28, savePath: "TwentyEighthCar")
        let image29Rect = CGRect(x: 0, y: 0, width: image29.size.width, height: image29.size.height)
        let (tll29, tlr29) = StaticTaillightDetector().positionTaillights(frame: image29Rect)
        saveTaillightImages(from: image29, tll: tll29, tlr: tlr29, savePath: "TwentyNinthCar")
        let image30Rect = CGRect(x: 0, y: 0, width: image30.size.width, height: image30.size.height)
        let (tll30, tlr30) = StaticTaillightDetector().positionTaillights(frame: image30Rect)
        saveTaillightImages(from: image30, tll: tll30, tlr: tlr30, savePath: "ThirtiethCar")
        let image31Rect = CGRect(x: 0, y: 0, width: image31.size.width, height: image31.size.height)
        let (tll31, tlr31) = StaticTaillightDetector().positionTaillights(frame: image31Rect)
        saveTaillightImages(from: image31, tll: tll31, tlr: tlr31, savePath: "ThirtyFirstCar")
        let image32Rect = CGRect(x: 0, y: 0, width: image32.size.width, height: image32.size.height)
        let (tll32, tlr32) = StaticTaillightDetector().positionTaillights(frame: image32Rect)
        saveTaillightImages(from: image32, tll: tll32, tlr: tlr32, savePath: "ThirtySecondCar")
    }
    
    func saveImage(_ image: UIImage, to path: String) -> Bool {
        if let pngData = image.pngData() {
            do {
                try pngData.write(to: URL(fileURLWithPath: path))
                print("Bild erfolgreich gespeichert: \(path)")
                return true
            } catch {
                print("Fehler beim Speichern des Bildes: \(error)")
                return false
            }
        } else {
            print("Fehler: Bild konnte nicht in PNG-Daten konvertiert werden.")
            return false
        }
    }
    
    func saveTaillightImages(from image: UIImage, tll: CGRect, tlr: CGRect, savePath: String) {
        // Schneide die Bilder aus
        guard let leftTaillightImage = StaticTaillightDetector().cropImage(from: image, to: tll) else {
            print("Fehler: Linkes Rücklicht konnte nicht ausgeschnitten werden.")
            return
        }
        
        guard let rightTaillightImage = StaticTaillightDetector().cropImage(from: image, to: tlr) else {
            print("Fehler: Rechtes Rücklicht konnte nicht ausgeschnitten werden.")
            return
        }
        
        let leftImagePath = NSHomeDirectory() + "/Documents/\(savePath)/left_taillight.png"
        let rightImagePath = NSHomeDirectory() + "/Documents/\(savePath)/right_taillight.png"
        
        if saveImage(leftTaillightImage, to: leftImagePath) {
            print("Linkes Rücklicht gespeichert: \(leftImagePath)")
        }
        
        if saveImage(rightTaillightImage, to: rightImagePath) {
            print("Rechtes Rücklicht gespeichert: \(rightImagePath)")
        }
    }
}

    /*
    var testImagesDirectory: URL!
    var classifier: DifferentialTaillightClassifier!

    override func setUp() {
        super.setUp()
        classifier = DifferentialTaillightClassifier()
        testImagesDirectory = URL(fileURLWithPath: "/Users/burak/Desktop/fh/5.Semester/Swift/yolo-ios-app/YOLOTests")
        
        if !FileManager.default.fileExists(atPath: testImagesDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: testImagesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                XCTFail("Testordner konnte nicht erstellt werden: \(error)")
            }
        }
    }
    

    func testSaveTaillightImages() {
        let bundle = Bundle(for: type(of: self))
        guard let path1 = bundle.path(forResource: "TaillightLeftON", ofType: "png"),
              let path2 = bundle.path(forResource: "TaillightRightON", ofType: "png"),
              let path3 = bundle.path(forResource: "TaillightLeft_ON", ofType: "png") else {
            XCTFail("Bilder konnten nicht gefunden werden")
            return
        }

        guard let image1 = UIImage(contentsOfFile: path1), let image2 = UIImage(contentsOfFile: path2), let image3 = UIImage(contentsOfFile: path3) else {
            XCTFail("Bild konnte nicht geladen werden")
            return
        }

        print("Bilder erfolgreich geladen")

        let image1Rect = CGRect(x: 0, y: 0, width: image1.size.width, height: image1.size.height)
        let (tll, tlr) = StaticTaillightDetector().positionTaillights(frame: image1Rect)
        saveTaillightImages(from: image1, tll: tll, tlr: tlr, savePath: "FirstCar")
        
        let image2Rect = CGRect(x: 0, y: 0, width: image2.size.width, height: image2.size.height)
        let (tll2, tlr2) = StaticTaillightDetector().positionTaillights(frame: image2Rect)
        saveTaillightImages(from: image2, tll: tll2, tlr: tlr2, savePath: "SecondCar")
        
        let image3Rect = CGRect(x: 0, y: 0, width: image3.size.width, height: image3.size.height)
        let (tll3, tlr3) = StaticTaillightDetector().positionTaillights(frame: image3Rect)
        saveTaillightImages(from: image3, tll: tll3, tlr: tlr3, savePath: "ThirdCar")

        
        let result = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image1, to: tll), lastImage: StaticTaillightDetector().cropImage(from: image2, to: tll2))
        XCTAssertTrue(result, "Das Rücklicht sollte als unterschiedlich klassifiziert werden.")
        let result2 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image1, to: tlr), lastImage: StaticTaillightDetector().cropImage(from: image2, to: tlr2))
        XCTAssertTrue(result2, "Das Rücklicht sollte als unterschiedlich klassifiziert werden.")
        
        
        
        let result3 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image1, to: tlr), lastImage: StaticTaillightDetector().cropImage(from: image1, to: tlr))
        XCTAssertFalse(result3, "Das Rücklicht sollte als ähnlich klassifiziert werden.")
        let result4 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image1, to: tll), lastImage: StaticTaillightDetector().cropImage(from: image1, to: tll))
        XCTAssertFalse(result4, "Das Rücklicht sollte als ähnlich klassifiziert werden.")
        
        
        let result5 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image2, to: tlr2), lastImage: StaticTaillightDetector().cropImage(from: image2, to: tlr2))
        XCTAssertFalse(result5, "Das Rücklicht sollte als ähnlich klassifiziert werden.")
        let result6 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image2, to: tll2), lastImage: StaticTaillightDetector().cropImage(from: image2, to: tll2))
        XCTAssertFalse(result6, "Das Rücklicht sollte als ähnlich klassifiziert werden.")
        
        let result7 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image3, to: tll3), lastImage: StaticTaillightDetector().cropImage(from: image1, to: tll))
        XCTAssertTrue(result7, "Das Rücklicht sollte als unterschiedlich klassifiziert werden.")
        let result8 = classifier.classifyTaillight(currentImage: StaticTaillightDetector().cropImage(from: image3, to: tlr3), lastImage: StaticTaillightDetector().cropImage(from: image1, to: tlr))
        XCTAssertTrue(result8, "Das Rücklicht sollte als unterschiedlich klassifiziert werden.")
        
    }
    
}
*/
