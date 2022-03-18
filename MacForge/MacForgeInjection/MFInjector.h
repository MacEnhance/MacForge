//
//  Injector.h
//  Injector
//
//  Created by Wolfgang Baird on 8/8/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MFInjectorProtocol

- (void)folderSetup:(void (^)(mach_error_t))reply;
- (void)injectProcess:(pid_t)pid;
//- (void)injectBundle:(const char *)bundlePackageFileSystemRepresentation inProcess:(pid_t)pid withReply:(void (^)(mach_error_t))reply;
- (void)installFramework:(NSString *)frameworkPath atlocation:(NSString*)frameworkDestinationPath withReply:(void (^)(mach_error_t))reply;

@end

@interface MFInjector : NSObject <NSXPCListenerDelegate, MFInjectorProtocol>

- (void)run;

@end
