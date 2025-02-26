import XCTest
@testable import YOLO

class BerRingBufferTests: XCTestCase {
    
    func testRingBufferAppendAndGetBuffer() {
        let buffer = BerRingBuffer(capacity: 5, fileName: "Test")
        
        // Test: Hinzufügen von Elementen
        buffer.append(1)
        buffer.append(2)
        buffer.append(3)
        
        var result = buffer.getBuffer()
        XCTAssertEqual(result, [1, 2, 3], "Die gespeicherten Elemente sollten korrekt zurückgegeben werden.")
        
        // Test: Hinzufügen von mehr Elementen, als der Buffer Platz hat
        buffer.append(4)
        buffer.append(5)
        buffer.append(6)  // Wird 1 überschreiben, da Buffer Kapazität 5 hat
        
        result = buffer.getBuffer()
        XCTAssertEqual(result, [2, 3, 4, 5, 6], "Der älteste Wert sollte überschrieben werden, wenn der Buffer voll ist.")
        
        // Test: Prüfen, ob der Buffer voll ist
        XCTAssertTrue(buffer.isFull, "Der Buffer sollte voll sein.")
    }
    
    func testRingBufferSizeAndEmpty() {
        let buffer = BerRingBuffer(capacity: 3, fileName: "Test")
        
        // Test: Prüfen der initialen Größe und leerem Zustand
        XCTAssertTrue(buffer.isEmpty, "Der Buffer sollte leer sein.")
        XCTAssertEqual(buffer.size, 0, "Die Größe des Buffers sollte 0 sein.")
        
        // Test: Hinzufügen von einem Element
        buffer.append(10)
        XCTAssertEqual(buffer.size, 1, "Die Größe des Buffers sollte 1 sein, nachdem ein Element hinzugefügt wurde.")
        
        // Test: Buffer leeren
        buffer.append(20)
        buffer.append(30)
        buffer.append(40)  // Buffer wird voll und überschreibt 10
        buffer.append(50)   // Buffer überschreibt 20
        
        let result = buffer.getBuffer()
        XCTAssertEqual(result, [30, 40, 50], "Der Buffer sollte die letzten 3 Elemente korrekt speichern.")
    }
}
