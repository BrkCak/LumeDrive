import UIKit

class DifferentialTaillightClassifier {
    private let wrapper: DifferentialTaillightClassifierWrapper

    init() {
        self.wrapper = DifferentialTaillightClassifierWrapper()
    }

    func classifyTaillight(currentImage: UIImage?, lastImage: UIImage?) -> Bool {
        guard let currentImage = currentImage, let lastImage = lastImage else {
            return false
        }
        return wrapper.classifyTaillight(currentImage, last: lastImage)
    }
}
