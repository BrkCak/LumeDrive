#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DifferentialTaillightClassifierWrapper : NSObject

- (BOOL)classifyTaillight:(UIImage *)currentImage lastImage:(UIImage *)lastImage;

@end
