//
//  DifferentialTaillightClassifier.swift
//  YOLO
//
//  Created by Burak Cakir on 13.11.24.
//  Copyright © 2024 Ultralytics. All rights reserved.
//


import UIKit
import CoreImage

class DifferentialTaillightClassifier {

    var lastTlDiffs: [Int: (Double, Bool)] = [:]

    init() {}

    func classifyTaillight(img: UIImage?, lastImg: UIImage?, tlId: Int = 0) -> Bool {
        guard let img = img, let lastImg = lastImg else { return false }

        // Konvertiere die Bilder in Graustufen
        guard let grayImg = self.convertToGrayScale(image: img),
              let grayLastImg = self.convertToGrayScale(image: lastImg) else {
            return false
        }

        // Berechne den absoluten Unterschied zwischen den Bildern
        let diff = self.absDiff(image1: grayLastImg, image2: grayImg)
        let maxDiff = self.maxValue(in: diff)
        let meanMaxDiff = self.meanOfTopValues(in: diff, count: 30)

        let (lastMeanMaxDiff, lastRet) = lastTlDiffs[tlId] ?? (0, false)

        var ret: Bool
        if meanMaxDiff > 90 {
            ret = true
        } else if meanMaxDiff < 30 {
            ret = false
        } else if meanMaxDiff - lastMeanMaxDiff > 20 {
            ret = true
        } else if meanMaxDiff - lastMeanMaxDiff < -20 {
            ret = false
        } else {
            ret = lastRet
        }

        print("Maximum Difference: \(maxDiff)  Mean Maximum Difference: \(meanMaxDiff)  Returns: \(ret)")

        lastTlDiffs[tlId] = (meanMaxDiff, ret)
        return ret
    }

    private func convertToGrayScale(image: UIImage) -> CIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        return ciImage.applyingFilter("CIColorControls", parameters: ["inputSaturation": 0])
    }

    private func absDiff(image1: CIImage, image2: CIImage) -> CIImage {
        return image1.applyingFilter("CIDifferenceBlendMode", parameters: ["inputBackgroundImage": image2])
    }

    private func maxValue(in image: CIImage) -> Double {
        // Hier müsste ein externer Ansatz verwendet werden, um das Maximum zu berechnen.
        return 100.0 // Platzhalterwert
    }

    private func meanOfTopValues(in image: CIImage, count: Int) -> Double {
        // Hier müsste ein externer Ansatz verwendet werden, um den Durchschnitt der größten Werte zu berechnen.
        return 50.0 // Platzhalterwert
    }
}
