//
//  Injector.h
//  Injector
//
//  Created by Erwan Barrier on 8/8/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MFInjectorProtocol

- (void)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation withReply:(void (^)(mach_error_t))reply;
- (void)inject:(pid_t)pid withLib:(const char *)executablePath withReply:(void (^)(mach_error_t))reply;

@end

@interface MFInjector : NSObject <NSXPCListenerDelegate, MFInjectorProtocol>

- (void)run;

@end
