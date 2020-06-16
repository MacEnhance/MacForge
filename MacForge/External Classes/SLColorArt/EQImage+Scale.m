//
//  UIImage+Scale.m
//  ColorArt
//
//  Created by Fred Leitz on 2012-12-15.
//  Copyright (c) 2012 Fred Leitz. All rights reserved.
//

#import "EQImage+Scale.h"

@implementation EQImage (Scale)
- (EQImage*) scaledToSize:(CGSize)newSize {
//    CGContextRef ref;
    EQImage *finalImage;
    
#if TARGET_OS_IPHONE
    UIGraphicsBeginImageContext(newSize);
#else
    finalImage = [[NSImage alloc] initWithSize:newSize];
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:NULL
                             pixelsWide:newSize.width
                             pixelsHigh:newSize.height
                             bitsPerSample:8
                             samplesPerPixel:4
                             hasAlpha:YES
                             isPlanar:NO
                             colorSpaceName:NSCalibratedRGBColorSpace
                             bytesPerRow:0
                             bitsPerPixel:0];
    [finalImage addRepresentation:rep];
    [finalImage lockFocus];

//    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];    
#endif

    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
#if TARGET_OS_IPHONE
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    finalImage = newImage;
#else
    [finalImage unlockFocus];
#endif

    
    return finalImage;
}
@end
