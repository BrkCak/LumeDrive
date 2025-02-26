#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DifferentialTaillightClassifierWrapper : NSObject

@property (nonatomic, copy) NSString *sideIdentifier;

- (BOOL)classifyTaillight:(UIImage *)currentImage lastImage:(UIImage *)lastImage;

@end
