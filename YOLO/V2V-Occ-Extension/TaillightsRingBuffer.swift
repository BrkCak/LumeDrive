import UIKit
/**
 * The `TaillightsRingBuffer` class manages a fixed-size buffer of taillight images.
 */
class TaillightsRingBuffer {
    /// The buffer storing taillight images.
    public var buffer: [UIImage] = []
    /// The maximum number of images that can be stored.
    private let maxSize = 2
    /// Counter to keep track of buffer saves.
    private var saveCounter = 0
    /**
     * Adds a new image to the buffer. If the buffer exceeds its maximum size, the oldest image is removed.
     *
     * @param image The image to be added to the buffer.
     */
    func addImage(_ image: UIImage) {
        if self.buffer.count >= self.maxSize {
            self.buffer.removeFirst()
        }
        self.buffer.append(image)
    }
    /**
     * Saves the current buffer contents to disk.
     *
     * @param name The name used for saving the buffer.
     */
    func saveBufferToDisk(name: String) {
        let fileManager = FileManager.default
        
        let baseDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let bufferDir = baseDir.appendingPathComponent("TaillightBuffers")
        
        if !fileManager.fileExists(atPath: bufferDir.path) {
            try? fileManager.createDirectory(at: bufferDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let saveDir = bufferDir.appendingPathComponent("\(name)_Buffer_\(saveCounter)")
        try? fileManager.createDirectory(at: saveDir, withIntermediateDirectories: true, attributes: nil)
        
        for (index, image) in buffer.enumerated() {
            let imagePath = saveDir.appendingPathComponent("image_\(index).png")
            if let imageData = image.pngData() {
                try? imageData.write(to: imagePath)
            }
        }
        
        saveCounter += 1
    }
    
    /**
     * Retrieves all images stored in the buffer.
     *
     * @return An array of `UIImage` objects.
     */
    func getImages() -> [UIImage] {
        return buffer
    }
    
    /**
     * Retrieves the first image stored in the buffer.
     *
     * @return The first `UIImage`, or `nil` if the buffer is empty.
     */
    func getFirstImage() -> UIImage? {
        return buffer.first
    }
    
    /**
     * Retrieves the last image stored in the buffer.
     *
     * @return The last `UIImage`, or `nil` if the buffer is empty.
     */
    func getLastImage() -> UIImage? {
        return buffer.last
    }
}
