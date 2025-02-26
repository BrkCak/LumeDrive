#import "DifferentialTaillightClassifierWrapper.h"
#import <opencv2/opencv.hpp>

@implementation DifferentialTaillightClassifierWrapper {
    double _lastMeanMaxDiff;
    BOOL _lastResult;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lastMeanMaxDiff = 0.0;
        _lastResult = NO;
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
    
    cv::Mat grayCurrent = [self processImage:currentMat];
    cv::Mat grayLast = [self processImage:lastMat];
    
    if (grayLast.size() != grayCurrent.size()) {
        cv::resize(grayLast, grayLast, grayCurrent.size());
    }
    
    cv::Mat diff;
    cv::absdiff(grayLast, grayCurrent, diff);
    
    //DEBUG Images
    /*[self saveDebugImagesWithCurrentImage:currentImage
                                lastImage:lastImage
                              grayCurrent:grayCurrent
                                 grayLast:grayLast
                                     diff:diff];
    */
    double meanMaxDiff = [self calculateMeanMaxDiff:diff];
    
    double previousMean = _lastMeanMaxDiff;
    BOOL previousResult = _lastResult;
    
    BOOL result = [self decideResult:meanMaxDiff previousMean:previousMean previousResult:previousResult];
    
    //[self logDebugInfo:diff currentMean:meanMaxDiff previousMean:previousMean result:result];
    
    _lastMeanMaxDiff = meanMaxDiff;
    _lastResult = result;
    
    return result;
}

#pragma mark - Entscheidungslogik (entsprechend Python-Version)
- (BOOL)decideResult:(double)meanMaxDiff
       previousMean:(double)previousMean
    previousResult:(BOOL)previousResult {
    
    if (meanMaxDiff > 90.0) {
        return YES;
    } else if (meanMaxDiff < 30.0) {
        return NO;
    }
    
    double delta = meanMaxDiff - previousMean;
    if (delta > 20.0) {
        return YES;
    } else if (delta < -20.0) {
        return NO;
    }
    
    return previousResult;
}

#pragma mark - Debug Info
- (void)logDebugInfo:(cv::Mat)diff
       currentMean:(double)currentMean
     previousMean:(double)previousMean
            result:(BOOL)result {
    
    double max_diff;
    cv::minMaxLoc(diff, nullptr, &max_diff);
    
    NSLog(@"Maximum Difference: %3.0f  Mean Maximum Difference: %5.1f  Returns: %@",
          max_diff,
          currentMean,
          result ? @"True" : @"False");
}

#pragma mark - Verarbeitungsschritte

- (cv::Mat)processImage:(cv::Mat)inputMat {
    cv::Mat grayMat;
    cv::Mat bgrMat;
    cv::cvtColor(inputMat, bgrMat, cv::COLOR_RGBA2BGR);  // iOS RGBA → OpenCV BGR
    cv::cvtColor(bgrMat, grayMat, cv::COLOR_BGR2GRAY);   // Umwandlung in Graustufen (wie in Python)
    return grayMat;
}

- (double)calculateMeanMaxDiff:(cv::Mat)diff {
    cv::Mat flat = diff.reshape(1, 1);
    cv::Mat sorted;
    cv::sort(flat, sorted, cv::SORT_DESCENDING);
    int range = MIN(30, sorted.cols);
    cv::Mat top30 = sorted.colRange(0, range);
    return cv::mean(top30)[0];

}

#pragma mark - Bildkonvertierung

- (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    cv::Mat mat(height, width, CV_8UC4);
    
    CGContextRef context = CGBitmapContextCreate(
        mat.data,
        width,
        height,
        8,
        mat.step,
        colorSpace,
        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault
    );
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return mat;
}

#pragma mark - Getter für Graubildkonvertierung

- (UIImage *)convertToGrayImage:(UIImage *)image {
    if (!image) {
        return nil;
    }

    cv::Mat colorMat = [self cvMatFromUIImage:image];
    if (colorMat.empty()) {
        return nil;
    }

    cv::Mat grayMat;
    cv::cvtColor(colorMat, grayMat, cv::COLOR_BGR2GRAY);

    return [self UIImageFromCVMat:grayMat];
}

- (UIImage *)UIImageFromCVMat:(cv::Mat)mat {
    NSData *data = [NSData dataWithBytes:mat.data length:mat.elemSize() * mat.total()];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows, 8, 8, mat.step[0], colorSpace, kCGImageAlphaNone, provider, NULL, false, kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

#pragma mark - Debug Image Saving

- (void)saveDebugImagesWithCurrentImage:(UIImage *)currentImage
                             lastImage:(UIImage *)lastImage
                           grayCurrent:(cv::Mat)grayCurrent
                              grayLast:(cv::Mat)grayLast
                                  diff:(cv::Mat)diff {
    // Pfad zum Dokumentenverzeichnis
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    // Aktuelles Zeitstempel für Dateinamen
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd_HHmmssSSS"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    // Speichere Originalbilder
    [self saveImage:currentImage withName:[NSString stringWithFormat:@"current_%@.png", timestamp] inDirectory:documentsDirectory];
    [self saveImage:lastImage withName:[NSString stringWithFormat:@"last_%@.png", timestamp] inDirectory:documentsDirectory];
    
    // Konvertiere und speichere Graustufenbilder
    UIImage *grayCurrentImage = [self UIImageFromCVMat:grayCurrent];
    UIImage *grayLastImage = [self UIImageFromCVMat:grayLast];
    [self saveImage:grayCurrentImage withName:[NSString stringWithFormat:@"gray_current_%@.png", timestamp] inDirectory:documentsDirectory];
    [self saveImage:grayLastImage withName:[NSString stringWithFormat:@"gray_last_%@.png", timestamp] inDirectory:documentsDirectory];
    
    // Konvertiere und speichere Differenzbild (mit Normalisierung)
    cv::Mat diffNormalized;
    cv::normalize(diff, diffNormalized, 0, 255, cv::NORM_MINMAX, CV_8UC1);
    UIImage *diffImage = [self UIImageFromCVMat:diffNormalized];
    [self saveImage:diffImage withName:[NSString stringWithFormat:@"diff_%@.png", timestamp] inDirectory:documentsDirectory];
}

- (void)saveImage:(UIImage *)image withName:(NSString *)name inDirectory:(NSString *)directory {
    if (!image || !name || !directory) return;
    NSString *filePath = [directory stringByAppendingPathComponent:name];
    NSData *pngData = UIImagePNGRepresentation(image);
    [pngData writeToFile:filePath atomically:YES];
    NSLog(@"Debug image saved: %@", filePath);
}

@end
