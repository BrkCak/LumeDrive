#import "DifferentialTaillightClassifierWrapper.h"
#import <opencv2/opencv.hpp>
#import <map>

@implementation DifferentialTaillightClassifierWrapper {
    double lastMeanMaxDiff; // Speichert den letzten Mittelwert
    BOOL lastRet;           // Speichert das letzte Klassifikationsergebnis
}

- (instancetype)init {
    self = [super init];
    if (self) {
        lastMeanMaxDiff = 0.0;
        lastRet = NO;
    }
    return self;
}

- (BOOL)classifyTaillight:(UIImage *)currentImage
                lastImage:(UIImage *)lastImage {
    if (!currentImage || !lastImage) {
        return NO;
    }
    
    cv::Mat currentMat = [self cvMatFromUIImage:currentImage];
    cv::Mat lastMat = [self cvMatFromUIImage:lastImage];

    if (currentMat.empty() || lastMat.empty()) {
        std::cerr << "Fehler: Eine der Matrizen ist leer." << std::endl;
        return NO;
    }

    //DEBUG
    //std::cout << "currentMat size: " << currentMat.size() << ", lastMat size: " << lastMat.size() << std::endl;

    if (currentMat.size() != lastMat.size()) {
        cv::resize(lastMat, lastMat, currentMat.size());
    }

    cv::Mat grayCurrent, grayLast;
    cv::cvtColor(currentMat, grayCurrent, cv::COLOR_BGR2GRAY);
    cv::cvtColor(lastMat, grayLast, cv::COLOR_BGR2GRAY);

    cv::Mat diff;
    cv::absdiff(grayCurrent, grayLast, diff);
    
    cv::Mat sortedDiff;
    cv::sort(diff.reshape(1, 1), sortedDiff, cv::SORT_DESCENDING);

    if (sortedDiff.empty() || sortedDiff.cols <= 0) {
        std::cerr << "Fehler: sortierte Differenzmatrix ist ungültig." << std::endl;
        return NO;
    }

    int range = std::min(30, sortedDiff.cols);
    if (range <= 0 || range > sortedDiff.cols) {
        std::cerr << "Fehler: Ungültiger Bereich für sortedDiff." << std::endl;
        return NO;
    }

    double meanMaxDiff = cv::mean(sortedDiff.colRange(0, range))[0];

    BOOL ret = lastRet;
    if (meanMaxDiff > 90) {
        ret = YES;
    } else if (meanMaxDiff < 30) {
        ret = NO;
    } else if ((meanMaxDiff - lastMeanMaxDiff) > 20) {
        ret = YES;
    } else if ((meanMaxDiff - lastMeanMaxDiff) < -20) {
        ret = NO;
    }

    lastMeanMaxDiff = meanMaxDiff;
    lastRet = ret;

    return ret;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGImageRef imageRef = [image CGImage];
    size_t widthSize = CGImageGetWidth(imageRef);
    size_t heightSize = CGImageGetHeight(imageRef);
    
    if (widthSize > std::numeric_limits<int>::max() || heightSize > std::numeric_limits<int>::max()) {
        std::cerr << "Fehler: Bildgröße überschreitet den unterstützten Bereich." << std::endl;
        return cv::Mat(); // Gib eine leere Matrix zurück
    }

    int width = static_cast<int>(widthSize);
    int height = static_cast<int>(heightSize);

    cv::Mat mat(height, width, CV_8UC4); // ARGB-Bild
    CGContextRef context = CGBitmapContextCreate(mat.data, width, height, 8, mat.step[0],
                                                 CGColorSpaceCreateDeviceRGB(),
                                                 kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);

    if (!context) {
        std::cerr << "Fehler: Kontext konnte nicht erstellt werden." << std::endl;
        return cv::Mat(); // Gib eine leere Matrix zurück
    }

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return mat;
}

@end
