//
//  OpenCVWrapper.m
//  CoinApp
//
//  Created by Maxim on 10/19/16.
//  Copyright (c) 2016 Maxim. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "UIImage+Rotate.h"
#import "UIImage+Scale.h"
#import "UIImage+Crop.h"
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

#include <vector>

std::vector<std::vector<cv::Mat>> edgedTemplates;

@implementation OpenCVWrapper

+ (UIImage *)convertToGrayscale:(UIImage *)image
{
    cv::Mat mat = [self cvMatFromUIImage:image];
    cv::Mat greyMat;
    cv::cvtColor(mat, greyMat, cv::COLOR_BGR2GRAY);
    return [self imageFromCVMat:greyMat];
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (UIImage *)imageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (cv::Mat)cvMatFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    cv::Mat image = cv::Mat(bufferHeight, bufferWidth, CV_8UC4, pixel);
    
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
    
    return image;
}

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    cv::Mat mat = [OpenCVWrapper cvMatFromSampleBuffer:sampleBuffer];
    UIImage *image = [OpenCVWrapper imageFromCVMat:mat];
    return image;
}

+ (UIImage *)sharpenImage:(UIImage *)image
{
    cv::Mat imageMat = [OpenCVWrapper cvMatFromUIImage:image];
    cv::Mat tempMat;
    cv::GaussianBlur(imageMat, tempMat, cv::Size(0, 0), 3);
    cv::addWeighted(imageMat, 1.5, tempMat, -0.5, 0, imageMat);
    return [OpenCVWrapper imageFromCVMat:imageMat];
}

+ (NSDictionary *)doTemplateMatch:(UIImage *)image
{
    NSLog(@"start --- %f", [[NSDate date] timeIntervalSince1970]);
    
    //cv::Mat imageMat;
    cv::Mat imageMat, edged;
    imageMat = [OpenCVWrapper cvMatFromUIImage:image];
    cvtColor(imageMat, edged, cv::COLOR_BGRA2GRAY);
    Canny(edged, edged, 60, 140);
    
    UIImage *tmpImage1 = [OpenCVWrapper imageFromCVMat:edged];
    
    double maxCoeff = DBL_MIN;
    cv::Point maxPoint;
    maxPoint.x = 0;
    maxPoint.y = 0;
    int templateIndex = -1;
    int templateWidth = 0, templateHeight = 0;
    for (int i = 0; i < edgedTemplates.size(); i ++) {
        std::vector<cv::Mat> sub_templates = edgedTemplates.at(i);
        for (int j = 0; j < sub_templates.size(); j ++) {
            cv::Mat templateImage = sub_templates.at(j);
            cv::Mat matchedImage;
            matchTemplate(edged, templateImage, matchedImage, cv::TM_CCOEFF);
            //matchTemplate(imageMat, templateImage, matchedImage, cv::TM_CCOEFF);
            double minVal, maxVal;
            cv::Point minLoc, maxLoc;
            minMaxLoc(matchedImage, &minVal, &maxVal, &minLoc, &maxLoc);
            if (maxCoeff < maxVal) {
                maxCoeff = maxVal;
                maxPoint = maxLoc;
                templateWidth = templateImage.cols;
                templateHeight = templateImage.rows;
                templateIndex = i;
            }
        }
    }
    
    NSLog(@"end --- %f", [[NSDate date] timeIntervalSince1970]);
    
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    resultDict[@"COEFF"] = [NSNumber numberWithDouble:maxCoeff];
    resultDict[@"RECT"] = [NSValue valueWithCGRect:CGRectMake(maxPoint.x, maxPoint.y, templateWidth, templateHeight)];
    resultDict[@"TYPE_INDEX"] = [NSNumber numberWithInt:templateIndex];
    
    return resultDict;
}

+ (NSDictionary *)detectCircle:(UIImage *)image
{
    cv::Mat imageMat;
    imageMat = [OpenCVWrapper cvMatFromUIImage:image];
    cvtColor(imageMat, imageMat, cv::COLOR_BGRA2GRAY);
    
//    cv::GaussianBlur(imageMat, imageMat, cv::Size(0, 0), 3);
    
    std::vector<cv::Vec3f> circles;
    
    CGFloat maxX = 0.f, maxY = 0.f, maxR = 0.f;
    for (int i = 4; i >= 1; i --) {
        int minRad = (int)((CGFloat)(imageMat.rows * i) / 10.f);
        cv::HoughCircles(imageMat, circles, cv::HOUGH_GRADIENT, 1, 2, 100, 100, minRad);
        if (circles.size() > 0) {
            for (int i = 0; i < circles.size(); i ++) {
                CGFloat x = circles[i][0];
                CGFloat y = circles[i][1];
                CGFloat r = circles[i][2];
                if (r > maxR) {
                    maxX = x;
                    maxY = y;
                    maxR = r;
                }
            }
            break;
        }
    }
    
    if (maxR == 0.f)
        return nil;
    else
        return @{@"X": [NSNumber numberWithFloat:maxX],
                 @"Y": [NSNumber numberWithFloat:maxY],
                 @"R": [NSNumber numberWithFloat:maxR]};
}

+ (void)setTemplates:(NSArray *)templates
{
    while (edgedTemplates.size() > 0) {
        std::vector<cv::Mat> sub_templates = edgedTemplates.back();
        sub_templates.clear();
        edgedTemplates.pop_back();
    }
    edgedTemplates.clear();
    
    if (templates == nil)
        return;
    
    for (NSDictionary *templateDict in templates) {
        std::vector<cv::Mat> sub_templates;
        
        UIImage *orgImage = [UIImage imageNamed:templateDict[@"FileName"]];
        NSInteger rotateCount = [templateDict[@"RotateCount"] integerValue];
        CGFloat featuredX = [templateDict[@"FeaturedX"] floatValue];
        CGFloat featuredY = [templateDict[@"FeaturedY"] floatValue];
        CGFloat featuredW = [templateDict[@"FeaturedW"] floatValue];
        CGFloat featuredH = [templateDict[@"FeaturedH"] floatValue];
        if (rotateCount < 1)
            rotateCount = 1;
        CGFloat rotateStepDegree = 360.f / (CGFloat)rotateCount;
        
        for (int i = 0; i < rotateCount; i ++) {
            CGFloat rotateDegree = (CGFloat)i * rotateStepDegree;
            UIImage *rotatedImage;
            rotatedImage = [orgImage circularRotateBy:((M_PI / 180.f) * rotateDegree)];
            rotatedImage = [rotatedImage crop:CGRectMake(featuredX, featuredY, featuredW, featuredH)];
            
            cv::Mat image = [OpenCVWrapper cvMatFromUIImage:rotatedImage];
            cv::Mat edgedImage;
            cv::cvtColor(image, edgedImage, cv::COLOR_BGR2GRAY);
            cv::Canny(edgedImage, edgedImage, 60, 140);
            
            UIImage *tempImage = [OpenCVWrapper imageFromCVMat:edgedImage];
            
            sub_templates.push_back(edgedImage);
            //sub_templates.push_back(image);
        }
        
        edgedTemplates.push_back(sub_templates);
    }
    
    return;
}

@end
