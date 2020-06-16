//
//  EQImage+Helper.m
//  ColorArt
//
//  Created by Christopher Füseschi on 16/02/2017.
//  Copyright © 2017 Fred Leitz. All rights reserved.
//

#import "EQImage+Helper.h"

@implementation EQImage (Helper)

- (CGImageRef)eq_cgImage
{
#if TARGET_OS_IPHONE
    return self.CGImage;
#else
    return [self CGImageForProposedRect:nil
                                context:nil
                                  hints:nil];
#endif
}

@end
