//
//  DKInstaller.h
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const DKInjectorExecutablLabel;
FOUNDATION_EXPORT NSString *const DKInstallerExecutablLabel;

@interface DKInstaller : NSObject

+ (BOOL)isInstalled;
+ (BOOL)install:(NSError **)error;

@end
