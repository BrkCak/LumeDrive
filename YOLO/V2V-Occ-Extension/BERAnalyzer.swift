import Foundation

class BERAnalyzer {
    let refString = "0000001010101100110010101110010011010010110011001101001011000110110000101110100011010010110111101101110001000000100101101100101011110010011101110101111011110001001110011111011011101000100011111110110"

    func bitStringToArray(_ string: String) -> [Int] {
        return string.compactMap { Int(String($0)) }
    }

    func evalBER(for bitArray: [Int]) -> ([Int], [Int], [Double], Double) {
        guard !bitArray.isEmpty else {
            fatalError("BitArray darf nicht leer sein.")
        }

        var refArray = bitStringToArray(refString)
        let lengthFactor = (bitArray.count / refArray.count) + 3
        refArray = Array(repeating: refArray, count: lengthFactor).flatMap { $0 }

        var bitMatches = Array(repeating: Array(repeating: 0, count: bitArray.count), count: 199)
        var ber = Array(repeating: 1.0, count: 199)

        for i in stride(from: 0, to: 398, by: 2) {
            let startIndex = i
            let endIndex = min(i + bitArray.count, refArray.count)
            let refSlice = Array(refArray[startIndex..<endIndex])

            if refSlice.count < bitArray.count { break }

            bitMatches[i / 2] = zip(bitArray, refSlice).map { $0 == $1 ? 1 : 0 }
            ber[i / 2] = 1.0 - Double(bitMatches[i / 2].reduce(0, +)) / Double(bitArray.count)
        }

        let channelOffsetLeft = 2 * findChannelOffset(
            bitMatches.map { Array($0.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }) },
            filterSize: 200
        )
        let channelOffsetRight = 2 * findChannelOffset(
            bitMatches.map { Array($0.enumerated().filter { $0.offset % 2 != 0 }.map { $0.element }) },
            filterSize: 200
        )

        var channelOffset = [Int]()
        for i in 0..<bitArray.count {
            if i % 2 == 0 {
                channelOffset.append(channelOffsetLeft)
            } else {
                channelOffset.append(channelOffsetRight)
            }
        }

        var bitMatchesWithOffset = [Int](repeating: 0, count: bitArray.count)
        for i in 0..<bitArray.count {
            let offset = channelOffset[i] / 2
            let adjustedIndex = max(0, min(bitMatches.count - 1, offset))
            bitMatchesWithOffset[i] = bitMatches[adjustedIndex][i]
        }

        let berWithOffset = 1.0 - Double(bitMatchesWithOffset.reduce(0, +)) / Double(bitArray.count)

        let movingBER = calcMovingBER(bitMatches: bitMatchesWithOffset, size: 300)

        return (bitMatchesWithOffset, channelOffset, movingBER, berWithOffset * 100)
    }
    
    func findChannelOffset(_ bitMatches: [[Int]], windowSize: Int = 200, filterSize: Int = 50) -> Int {
        guard !bitMatches.isEmpty, bitMatches[0].count >= windowSize else {
            return 0
        }

        var channelOffset = [Int](repeating: 0, count: bitMatches[0].count - windowSize)

        for i in 0..<(bitMatches[0].count - windowSize) {
            guard i + windowSize <= bitMatches[0].count else { continue }
            let bitMatchesWindow = bitMatches.map { Array($0[i..<i + windowSize]) }
            let bitMatchesSum = bitMatchesWindow.map { $0.reduce(0, +) }
            channelOffset[i] = bitMatchesSum.firstIndex(of: bitMatchesSum.max() ?? 0) ?? 0
        }

        var channelOffsetFiltered = [Int](repeating: -1, count: bitMatches[0].count)

        let adjustedFilterSize = min(filterSize, channelOffset.count)

        for i in 0..<channelOffset.count - adjustedFilterSize {
            let offsetWindow = Array(channelOffset[i..<(i + adjustedFilterSize)])
            if offsetWindow.min() == offsetWindow.max() {
                channelOffsetFiltered[windowSize / 2 + i] = channelOffset[i]
            }
        }

        let firstCorrectOffset = channelOffsetFiltered.firstIndex(where: { $0 >= 0 }) ?? 0
        for i in 0..<firstCorrectOffset {
            channelOffsetFiltered[i] = channelOffsetFiltered[firstCorrectOffset]
        }

        for i in 1..<channelOffsetFiltered.count where channelOffsetFiltered[i] < 0 {
            channelOffsetFiltered[i] = channelOffsetFiltered[i - 1]
        }

        return channelOffsetFiltered[windowSize / 2]
    }

    func calcMovingBER(bitMatches: [Int], size: Int = 300) -> [Double] {
        let n = bitMatches.count
        var movingBER = [Double](repeating: 0.0, count: n)
        
        for i in 0..<n {
            let start = max(0, i - size / 2)
            let end = min(n, i + size / 2)
            let bitMatchesPart = bitMatches[start..<end]
            let sum = bitMatchesPart.reduce(0, +)
            let average = Double(sum) / Double(bitMatchesPart.count)
            movingBER[i] = 1.0 - average
        }
        
        return movingBER
    }
}
