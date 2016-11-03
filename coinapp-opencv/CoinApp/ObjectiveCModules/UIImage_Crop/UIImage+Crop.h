/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIImage *croppedImage(UIImage *image, CGRect rcCrop);

@interface UIImage (Crop)

- (UIImage *) crop: (CGRect) rcCrop;

@end
