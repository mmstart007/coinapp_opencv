//
//  OpenCVWrapper.h
//  CoinApp
//
//  Created by Maxim on 10/19/16.
//  Copyright (c) 2016 Maxim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)convertToGrayscale:(UIImage *)image;
+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (UIImage *)sharpenImage:(UIImage *)image;
+ (NSDictionary *)doTemplateMatch:(UIImage *)image;
+ (NSDictionary *)detectCircle:(UIImage *)image;
+ (void)setTemplates:(NSArray *)templateImages;

@end
