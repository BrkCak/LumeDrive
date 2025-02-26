import Foundation

import Foundation

class BERAnalyzer {
    //let refBit = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    //let refBit = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    //let refBit = [0,1,0,1,0,1,0,0,0,1,1,0,0,1,0,1,0,1,1,1,0,0,1,1,0,1,1,1,0,1,0,0] //ASCI:"Test"
    let refBit = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    /// evaluate the ber
    func evalBER(for bitArray: [Int]) -> Double? {
        guard refBit.count == bitArray.count else {
            return nil
        }
        
        var errorCount = 0
        for (ref, bit) in zip(refBit, bitArray) {
            if ref != bit {
                errorCount += 1
            }
        }
        
        /// calc the ber
        let ber = Double(errorCount) / Double(refBit.count)
        return ber*100
    }
}
