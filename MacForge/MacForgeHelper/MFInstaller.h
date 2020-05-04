//
//  MFInstaller.h
//  Dark
//
//  Created by Wolfgang Baird on 8/11/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MFInjectorExecutablLabel;
FOUNDATION_EXPORT NSString *const MFInstallerExecutablLabel;

@interface MFInstaller : NSObject

+ (BOOL)isInstalled;
+ (BOOL)install:(NSError **)error;

@end
