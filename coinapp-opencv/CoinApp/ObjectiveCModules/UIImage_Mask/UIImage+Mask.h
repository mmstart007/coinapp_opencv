/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIImage *maskedImage(UIImage *image);

@interface UIImage (Mask)

- (UIImage *) applyMask;

@end
