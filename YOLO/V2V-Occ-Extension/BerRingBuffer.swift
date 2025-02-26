/**
# BerRingBuffer

A circular buffer implementation for storing and managing Bit Error Rate (BER) data.

## Overview
- Implements a fixed-size circular buffer for efficient BER data storage
- Provides methods for buffer manipulation and file-based persistence
- Formats and logs buffer contents with timestamps and BER values
- Supports real-time data streaming and analysis

## Key Features
- Efficient O(1) append and retrieval operations
- Automatic buffer overwrite when capacity is reached
- Formatted logging with 8-bit chunk visualization
- Thread-safe buffer access patterns
*/

class BerRingBuffer {
    // MARK: - Properties
    
    /// Underlying storage array for BER values
    private var buffer: [Int]
    /// Index for the oldest element (buffer head)
    private var head = 0
    /// Index for the newest element (buffer tail)
    private var tail = 0
    /// Current number of elements in buffer
    private var count = 0
    /// Maximum capacity of the buffer
    private let capacity: Int
    /// File URL for persistent storage
    private let fileURL: URL
    // MARK: - Initialization
    
    /**
     Initializes buffer with specified capacity and storage file
     - Parameters:
        - capacity: Maximum number of elements buffer can hold
        - fileName: Name for persistent storage file
     - Creates empty buffer array with specified capacity
     - Sets up file URL in documents directory
     */
    init(capacity: Int, fileName: String) {
        self.capacity = capacity
        self.buffer = Array(repeating: 0, count: capacity)
        
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentDirectory.appendingPathComponent(fileName)
    }
    // MARK: - Buffer Operations
    
    /**
     Adds new element to buffer
     - Parameter element: BER value to append (0 or 1)
     - Handles buffer wrap-around when capacity is reached
     - Maintains consistent head/tail pointers
     */
    func append(_ element: Int) {
        buffer[tail] = element
        tail = (tail + 1) % capacity
        if count == capacity {
            head = (head + 1) % capacity
        } else {
            count += 1
        }
        //self.saveBufferToFile()
    }

    /**
     Retrieves current buffer contents
     - Returns: Array of BER values in chronological order
     - Maintains original insertion sequence
     */
    func getBuffer() -> [Int] {
        var result: [Int] = []
        for i in 0..<count {
            let index = (head + i) % capacity
            result.append(buffer[index])
        }
        return result
    }
    // MARK: - Buffer State
    
    /// Current number of elements in buffer
    var size: Int {
        return count
    }
    /// Indicates if buffer has reached capacity
    var isFull: Bool {
        return count == capacity
    }
    /// Indicates if buffer is empty
    var isEmpty: Bool {
        return count == 0
    }
    // MARK: - Data Logging
    
    /**
     Saves current buffer state to file with metadata
     - Parameters:
        - berValue: Current BER percentage value
        - interval: Timestamp in milliseconds
     - Formats buffer contents into 8-bit chunks
     - Appends new log entry to existing file
     - Handles file creation and error cases
     */
    func saveBufferToFile(berValue: Double, interval: Double) {
        let binaryArray = getBuffer().map { String($0) }
        let binaryString = binaryArray.joined()
        var formattedBufferContents = ""
        var currentIndex = 0

        while currentIndex < binaryString.count {
            let endIndex = min(currentIndex + 8, binaryString.count)
            let start = binaryString.index(binaryString.startIndex, offsetBy: currentIndex)
            let end = binaryString.index(start, offsetBy: endIndex - currentIndex)
            let chunk = String(binaryString[start..<end])
            formattedBufferContents += chunk + " "
            currentIndex += 8
        }

        if !formattedBufferContents.isEmpty {
            formattedBufferContents = String(formattedBufferContents.dropLast())
        }

        let logEntry = "Timestamp: \(interval)ms | BER: \(String(format: "%.4f%%", berValue)) | Buffer: \(formattedBufferContents)\n"

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = logEntry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try logEntry.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("⚠️ Fehler beim Schreiben in die Datei: \(error)")
        }
    }
}
