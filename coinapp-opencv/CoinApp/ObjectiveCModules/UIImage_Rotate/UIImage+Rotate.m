/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */


#import "UIImage+Rotate.h"

UIImage *rotatedImage(UIImage *image, CGFloat rotation)
{
    // Calculate Destination Size
    CGAffineTransform t = CGAffineTransformMakeRotation(rotation);
    CGRect sizeRect = (CGRect) {.size = image.size};
    CGRect destRect = CGRectApplyAffineTransform(sizeRect, t);
    CGSize destinationSize = destRect.size;
    
    // Draw image
    UIGraphicsBeginImageContext(destinationSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, destinationSize.width / 2.0f, destinationSize.height / 2.0f);
    CGContextRotateCTM(context, rotation);
    [image drawInRect:CGRectMake(-image.size.width / 2.0f, -image.size.height / 2.0f, image.size.width, image.size.height)];
    
    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

UIImage *rotatedCircularImage(UIImage *image, CGFloat rotation)
{
    CGSize imageSize = image.size;
    // Draw image
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, imageSize.width / 2.0f, imageSize.height / 2.0f);
    CGContextRotateCTM(context, rotation);
    [image drawInRect:CGRectMake(-imageSize.width / 2.0f, -imageSize.height / 2.0f, imageSize.width, imageSize.height)];
    
    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@implementation UIImage (Rotation)
- (BOOL) isLandscape
{
    if (self.size.width > self.size.height)
        return YES;
    return NO;
}

- (BOOL) isPortrait
{
    return !(self.isLandscape);
}

- (UIImage *) rotateBy: (CGFloat) theta
{
    return rotatedImage(self, theta);
}

+ (UIImage *) image: (UIImage *) image rotatedBy: (CGFloat) theta
{
    return rotatedImage(image, theta);
}
    
- (UIImage *) circularRotateBy: (CGFloat) theta
{
    return rotatedCircularImage(self, theta);
}

+ (UIImage *) image: (UIImage *) image circularRotatedBy: (CGFloat) theta
{
    return rotatedCircularImage(image, theta);
}

@end
