/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIImage *scaledImage(UIImage *image, CGSize newSize);

@interface UIImage (Scale)

- (UIImage *) scaledTo: (CGSize) newSize;
+ (UIImage *) image: (UIImage *) image scaledTo: (CGSize) newSize;

@end
