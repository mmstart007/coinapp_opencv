/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */


#import "UIImage+Scale.h"

UIImage *scaledImage(UIImage *image, CGSize newSize)
{
    // Draw image
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@implementation UIImage (Scale)

- (UIImage *) scaledTo: (CGSize) newSize
{
    return scaledImage(self, newSize);
}

+ (UIImage *) image: (UIImage *) image scaledTo: (CGSize) newSize
{
    return scaledImage(image, newSize);
}

@end
