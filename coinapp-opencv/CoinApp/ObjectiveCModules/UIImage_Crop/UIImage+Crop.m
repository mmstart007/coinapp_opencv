/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */


#import "UIImage+Crop.h"

UIImage *croppedImage(UIImage *image, CGRect rcCrop)
{
    // Draw image
    UIGraphicsBeginImageContext(rcCrop.size);
    [image drawInRect:CGRectMake(-rcCrop.origin.x, -rcCrop.origin.y, image.size.width, image.size.height)];
    
    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@implementation UIImage (Crop)

- (UIImage *) crop: (CGRect) rcCrop
{
    return croppedImage(self, rcCrop);
}

@end
