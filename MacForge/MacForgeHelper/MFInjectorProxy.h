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

//- (BOOL)inject:(NSError **)error;
//- (void)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error;
//- (void)injectPID:(pid_t)pid withBundle:(NSString*)bundlePath withReply:(void (^)(BOOL))reply;
//- (BOOL)setupPluginFolder:(NSError **)error;
//- (void)setupPluginFolderWithReply:(void (^)(BOOL))reply;
//- (BOOL)installFramework:(NSString*)frameworkPath toLoaction:(NSString*)dest :(NSError **)error;

- (void)setupMacEnhanceFolder:(void (^)(mach_error_t))reply;
- (void)installFramework:(NSString *)frameworkPath atlocation:(NSString*)frameworkDestinationPath withReply:(void (^)(mach_error_t))reply;
- (void)injectBundle:(NSString *)bundle inProcess:(pid_t)pid withReply:(void (^)(mach_error_t))reply;

@end
