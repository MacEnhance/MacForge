//
//  TypeAliases.h
//  ColorArt
//
//  Created by Christopher Füseschi on 16/02/2017.
//  Copyright © 2017 Fred Leitz. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define EQImage UIImage
#define EQColor UIColor
#else
#import <AppKit/AppKit.h>
#define EQImage NSImage
#define EQColor NSColor
#endif
