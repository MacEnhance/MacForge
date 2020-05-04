//
//  MFInstaller.h
//  MFInstaller
//
//  Created by Wolfgang Baird on 8/11/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MFFrameworkDstPath;

extern dispatch_source_t g_timer_source;

@interface MFFrameworkInstaller : NSObject

@property (nonatomic, strong) NSError *error;

- (BOOL)installFramework:(NSString *)frameworkPath;
- (BOOL)setupPluginFolder;

@end
