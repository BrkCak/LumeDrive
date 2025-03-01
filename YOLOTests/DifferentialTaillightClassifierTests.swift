import XCTest
@testable import YOLO

class DifferentialTaillightClassifierTests: XCTestCase {
    
    var classifier: DifferentialTaillightClassifierWrapper!
    
    override func setUp() {
        super.setUp()
        classifier = DifferentialTaillightClassifierWrapper()
    }

    override func tearDown() {
        classifier = nil
        super.tearDown()
    }
    func test1() {
        let bundle = Bundle(for: type(of: self))
        guard let path1 = bundle.path(forResource: "current", ofType: "png")
        else {
            XCTFail("Bilder konnten nicht gefunden werden")
            return
        }
        guard let image1 = UIImage(contentsOfFile: path1)
        else {
            XCTFail("Bilder konnten nicht geladen werden")
            return
        }
        var state = classifier.classifyTaillight(image1, last: image1)
    }
    
    func testPoC() {
        let bundle = Bundle(for: type(of: self))
        
        guard let path1 = bundle.path(forResource: "Image1", ofType: "JPG"),
            let path2 = bundle.path(forResource: "Image2", ofType: "JPG"),
            let path3 = bundle.path(forResource: "Image3", ofType: "JPG"),
            let path4 = bundle.path(forResource: "Image4", ofType: "JPG"),
            let path5 = bundle.path(forResource: "image_0", ofType: "png"),
            let path6 = bundle.path(forResource: "image_1", ofType: "png")
        else {
            XCTFail("Bilder konnten nicht gefunden werden")
            return
        }
        guard let image1 = UIImage(contentsOfFile: path1),
              let image2 = UIImage(contentsOfFile: path2),
              let image3 = UIImage(contentsOfFile: path3),
              let image4 = UIImage(contentsOfFile: path4),
              let image5 = UIImage(contentsOfFile: path5),
              let image6 = UIImage(contentsOfFile: path6)
        else {
            XCTFail("Bilder konnten nicht geladen werden")
            return
        }
        
        var state = classifier.classifyTaillight(image2, last: image1)
        XCTAssertTrue(state, "State changed")
        //state = DifferentialTaillightClassifier().classifyTaillight(currentImage: image2, lastImage: image1, wrapper: classifier.leftTailLihtWrapper)
        //XCTAssertTrue(state, "State changed")
         
        state = classifier.classifyTaillight(image3, last: image2)
        XCTAssertTrue(state, "State changed")
        //state = DifferentialTaillightClassifier().classifyTaillight(currentImage: image3, lastImage: image2, wrapper: classifier.leftTailLihtWrapper)
        //XCTAssertTrue(state, "State changed")

        state = classifier.classifyTaillight(image4, last: image3)
        XCTAssertFalse(state, "State not changed")
        state = DifferentialTaillightClassifierWrapper().classifyTaillight(image4, last: image3)
        XCTAssertTrue(state, "State changed")
        
        var classifier1 = DifferentialTaillightClassifierWrapper()
        state = classifier1.classifyTaillight(image5, last: nil)
        XCTAssertFalse(state, "State not changed")
        state = classifier1.classifyTaillight(image6, last: image5)
        XCTAssertTrue(state, "State changed")
    }
    
    func saveImage(_ image: UIImage, to directory: String, filename: String) -> Bool {
        let fileManager = FileManager.default
        let directoryPath = NSHomeDirectory() + "/Documents/\(directory)"
        let filePath = directoryPath + "/\(filename).jpg"
        
        // Stelle sicher, dass das Verzeichnis existiert
        do {
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        } catch {
            print("Fehler beim Erstellen des Verzeichnisses: \(error)")
            return false
        }
        
        // Speichern des Bildes ohne Konvertierung, falls es bereits ein JPG ist
        guard let imageData = image.pngData() ?? image.jpegData(compressionQuality: 1.0) else {
            print("Fehler: Bild konnte nicht in Daten umgewandelt werden.")
            return false
        }
        
        do {
            try imageData.write(to: URL(fileURLWithPath: filePath))
            print("Bild erfolgreich gespeichert: \(filePath)")
            return true
        } catch {
            print("Fehler beim Speichern des Bildes: \(error)")
            return false
        }
    }
}
