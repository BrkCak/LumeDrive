#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject

// Funktion für Bildgrößenänderung
+ (UIImage *)resizeImage:(UIImage *)image width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
