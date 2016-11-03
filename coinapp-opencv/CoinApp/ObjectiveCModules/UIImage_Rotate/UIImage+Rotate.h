/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIImage *rotatedImage(UIImage *image, CGFloat rotation);

@interface UIImage (Rotation)
- (UIImage *) rotateBy: (CGFloat) theta;
- (UIImage *) circularRotateBy: (CGFloat) theta;
+ (UIImage *) image: (UIImage *) image rotatedBy: (CGFloat) theta;
+ (UIImage *) image: (UIImage *) image circularRotatedBy: (CGFloat) theta;

@property (nonatomic, readonly) BOOL isLandscape;
@property (nonatomic, readonly) BOOL isPortrait;
@end
