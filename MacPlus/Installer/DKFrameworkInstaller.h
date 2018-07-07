//
//  DKInstaller.h
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const DKFrameworkDstPath;

extern dispatch_source_t g_timer_source;

@interface DKFrameworkInstaller : NSObject

@property (nonatomic, strong) NSError *error;

- (BOOL)installFramework:(NSString *)frameworkPath;

@end
