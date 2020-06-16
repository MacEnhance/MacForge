//
//  UIImage+Scale.h
//  ColorArt
//
//  Created by Fred Leitz on 2012-12-15.
//  Copyright (c) 2012 Fred Leitz. All rights reserved.
//

#import "SLTypeAliases.h"

@interface EQImage (Scale)
- (EQImage*) scaledToSize:(CGSize)newSize;
@end
