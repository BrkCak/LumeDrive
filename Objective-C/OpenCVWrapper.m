#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation OpenCVWrapper

// UIImage -> cv::Mat
+ (cv::Mat)UIImageToMat:(UIImage *)image {
    NSData *imageData = UIImagePNGRepresentation(image);
    cv::Mat mat = cv::imdecode(cv::Mat(1, (int)imageData.length, CV_8UC1, (void*)imageData.bytes), cv::IMREAD_UNCHANGED);
    return mat;
}

// cv::Mat -> UIImage
+ (UIImage *)MatToUIImage:(const cv::Mat&)mat {
    NSData *imageData = [NSData dataWithBytes:mat.data length:mat.total() * mat.elemSize()];
    UIImage *image = [UIImage imageWithData:imageData];
    return image;
}

// Resize-Funktion
+ (UIImage *)resizeImage:(UIImage *)image width:(int)width height:(int)height {
    cv::Mat inputMat = [self UIImageToMat:image];
    cv::Mat resizedMat;
    cv::resize(inputMat, resizedMat, cv::Size(width, height), 0, 0, cv::INTER_CUBIC);
    return [self MatToUIImage:resizedMat];
}

@end
