//
//  MFInstaller.h
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MFInjectorExecutablLabel;
FOUNDATION_EXPORT NSString *const MFInstallerExecutablLabel;

@interface MFInstaller : NSObject

+ (BOOL)isInstalled;
+ (BOOL)install:(NSError **)error;

@end
