//
//  Injector.h
//  Injector
//
//  Created by Wolfgang Baird on 8/8/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MFInjectorProtocol

- (void)setupPluginFolderWithReply:(void (^)(mach_error_t))reply;
- (void)installFramework:(NSString *)frameworkPath withReply:(void (^)(mach_error_t))reply;
- (void)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation withReply:(void (^)(mach_error_t))reply;
- (void)inject:(pid_t)pid withLib:(const char *)libraryPath withReply:(void (^)(mach_error_t))reply;

@end

@interface MFInjector : NSObject <NSXPCListenerDelegate, MFInjectorProtocol>

- (void)run;

@end
