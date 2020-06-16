//
//  UIImage+ColorArt.h
//  ColorArt
//
//  Created by Fred Leitz on 2012-12-17.
//  Copyright (c) 2012 Fred Leitz. All rights reserved.
//

#import "SLColorArt.h"

@interface EQImage (ColorArt)

- (SLColorArt*) colorArt;
- (SLColorArt*) colorArt:(CGSize)scale;

@end
