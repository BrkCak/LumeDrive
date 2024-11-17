//
//  ImageHandler.swift
//  YOLO
//
//  Created by Burak Cakir on 08.11.24.
//  Copyright © 2024 Ultralytics. All rights reserved.
//
import UIKit

class ImageHandler {
    var currentImg: UIImage
    var lastImg: UIImage?

    init(currentImg: UIImage, lastImg: UIImage? = nil) {
        self.currentImg = currentImg
        self.lastImg = lastImg
    }

    // Gibt eine Kopie des aktuellen Bildes zurück
    func getCurrentImg() -> UIImage {
        return currentImg.copy() as! UIImage
    }

    // Gibt eine Kopie des letzten Bildes zurück, falls vorhanden
    func getLastImg() -> UIImage? {
        return lastImg?.copy() as? UIImage
    }
}
