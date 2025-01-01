import XCTest
@testable import YOLO

final class BERAnalyzerTests: XCTestCase {

    func testBitStringToArray() {
        let testString = "101010"
        let expectedResult = [1, 0, 1, 0, 1, 0]
        XCTAssertEqual(BERAnalyzer().bitStringToArray(testString), expectedResult)
        
        let emptyString = ""
        XCTAssertEqual(BERAnalyzer().bitStringToArray(emptyString), [])
    }
    
    func testFindChannelOffset() {
        let testBitMatches = [
            [1, 0, 1, 0, 1],
            [1, 1, 1, 0, 0],
            [0, 1, 0, 1, 1]
        ]
        
        let windowSize = 3
        let filterSize = 2
        let channelOffset = BERAnalyzer().findChannelOffset(testBitMatches, windowSize: windowSize, filterSize: filterSize)

        XCTAssertGreaterThanOrEqual(channelOffset, -1)
    }
    
    func testCalcMovingBER_AllOnes() {
        let bitMatches = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
        let size = 5
        let expectedBER = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        
        let result = BERAnalyzer().calcMovingBER(bitMatches: bitMatches, size: size)
        
        XCTAssertEqual(result, expectedBER, "BER should be 0 when all bits match.")
    }
    
    func testCalcMovingBER_MixedValues() {
        let bitMatches = [1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
        let size = 4
        let expectedBER = [0.5, 0.3, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.7]
        
        let result = BERAnalyzer().calcMovingBER(bitMatches: bitMatches, size: size)
        
        for (index, value) in result.enumerated() {
            XCTAssertEqual(value, expectedBER[index], accuracy: 0.1, "BER at index \(index) should match expected value.")
        }
    }
    
    func testEvaluateBER() {
        let analyzer = BERAnalyzer()
        var refArray1 = analyzer.refString.map { Int(String($0))! }
        let (_, _, _, berWithOffset) = analyzer.evalBER(for: refArray1)

        print("BER with Offset: \(berWithOffset)")
        XCTAssertEqual(berWithOffset, 0.0, accuracy: 0.1, "BER with offset should be 0%.")
        
        refArray1 = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        let (_, _, _, berWithOffset2) = analyzer.evalBER(for: refArray1)
        
        print("BER with Offset: \(berWithOffset2)")
        XCTAssertEqual(berWithOffset2, 57.7, accuracy: 0.1, "BER with offset should be 57.7%.")
    }
}
