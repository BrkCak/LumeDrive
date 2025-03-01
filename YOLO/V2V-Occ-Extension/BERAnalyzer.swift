import Foundation

class BERAnalyzer {
    //let refBit = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
    //let refBit = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    //let refBit = [0,1,0,1,0,1,0,0,0,1,1,0,0,1,0,1,0,1,1,1,0,0,1,1,0,1,1,1,0,1,0,0] //ASCI:"Test"
    let refBit = [0,1,0,1,0,1,1,0,0,1,1,0,0,1,0,1,0,1,1,1,0,0,1,0,0,1,1,0,1,0,0,1,0,1,1,0,0,1,1,0,0,1,1,0,1,0,0,1,0,1,1,0,0,0,1,1,0,1,1,0,0,0,0,1,0,1,1,1,0,1,0,0,0,1,1,0,1,0,0,1,0,1,1,0,1,1,1,1,0,1,1,0,1,1,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,1,0,1,1,0,1,1,1,1,0,1,1,0,0,1,0,0,0,1,1,0,0,1,0,1] //ASCI:"Verification Code"
    //let refBit = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    //let refBit = [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0]
    //let refBit = [1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0]
        
    func evalBER(for receivedBits: [Int]) -> Double? {
        guard receivedBits.count == refBit.count else {
            return nil
        }
        
        var minErrorCount = Int.max
        for shift in 0..<refBit.count {
            let shiftedBits = shiftBits(receivedBits, by: shift)
            let errorCount = calculateErrors(shiftedBits)
            if errorCount < minErrorCount {
                minErrorCount = errorCount
            }
        }
        
        let ber = Double(minErrorCount) / Double(refBit.count) * 100
        return ber
    }
    
    private func shiftBits(_ bits: [Int], by shift: Int) -> [Int] {
        Array(bits[shift...] + bits[0..<shift])
    }
    
    private func calculateErrors(_ bits: [Int]) -> Int {
        zip(refBit, bits).filter { $0 != $1 }.count
    }
}
