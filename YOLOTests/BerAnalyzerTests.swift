import XCTest
@testable import YOLO

final class BerAnalyzerTests: XCTestCase {
    var analyzer: BERAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = BERAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    func testEvalBERIdenticalArray() {
        let testArray = Array(repeating: 1, count: analyzer.refBit.count)
        let ber = analyzer.evalBER(for: testArray)
        XCTAssertNotNil(ber, "BER sollte nicht nil sein, wenn die Längen übereinstimmen")
        XCTAssertEqual(ber!, 0.0, accuracy: 1e-10, "BER sollte 0.0 sein, wenn beide Arrays identisch sind")
    }
    
    func testEvalBERAllErrors() {
        let testArray = Array(repeating: 0, count: analyzer.refBit.count)
        let ber = analyzer.evalBER(for: testArray)
        XCTAssertNotNil(ber, "BER sollte nicht nil sein, wenn die Längen übereinstimmen")
        XCTAssertEqual(ber!, 100, accuracy: 1e-10, "BER sollte 1.0 sein, wenn alle Bits falsch sind")
    }
    
    func testEvalBERHalfErrors() {
        let halfCount = analyzer.refBit.count / 2
        let testArray = Array(repeating: 1, count: halfCount) + Array(repeating: 0, count: analyzer.refBit.count - halfCount)
        let ber = analyzer.evalBER(for: testArray)
        XCTAssertNotNil(ber, "BER sollte nicht nil sein, wenn die Längen übereinstimmen")
        XCTAssertEqual(ber!, 50, accuracy: 1e-10, "BER sollte 0.5 sein, wenn 50% der Bits fehlerhaft sind")
    }
    
    func testEvalBERWrongLength() {
        let testArray = Array(repeating: 1, count: analyzer.refBit.count - 1)
        let ber = analyzer.evalBER(for: testArray)
        XCTAssertNil(ber, "BER sollte nil sein, wenn das Eingabearray eine falsche Länge hat")
    }
}
