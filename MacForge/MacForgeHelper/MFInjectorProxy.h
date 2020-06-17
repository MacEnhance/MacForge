//
//  InjectorWrapper.h
//  Dark
//
//  Created by Wolfgang Baird on 8/6/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <Foundation/Foundation.h>
#import <mach/mach_error.h>
#import "MFInjector.h"

@interface MFInjectorProxy : NSObject

- (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error;
- (BOOL)inject:(NSError **)error;

- (BOOL)setupPluginFolder:(NSError **)error;

- (BOOL)installMachInjectBundleFramework:(NSError **)error;
- (BOOL)installFramework:(NSString*)frameworkPath toLoaction:(NSString*)dest :(NSError **)error;

@end
