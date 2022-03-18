//
//  InjectorWrapper.m
//  Dark
//
//  Created by Wolfgang Baird on 8/6/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import "MFInjectorProxy.h"

@interface MFInjectorProxy ()
@property (atomic, strong, readwrite) NSXPCConnection *proxyConnection;
@property (atomic, strong, readwrite) id<MFInjectorProtocol> proxy;
@end

@implementation MFInjectorProxy

- (id)init {
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.proxyConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.macenhance.MacForge.Injector.mach" options:NSXPCConnectionPrivileged];
        self.proxyConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
        self.proxy = self.proxyConnection.remoteObjectProxy;
        [self.proxyConnection resume];
    }
    return self;
}

//- (void)injectBundle:(NSString *)bundle inProcess:(pid_t)pid withReply:(void (^)(mach_error_t))reply {
//    if (self.proxyConnection) {
//        // NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
//        // NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
//        // NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundle);
//        [self.proxyConnection.remoteObjectProxy injectBundle:bundle.fileSystemRepresentation inProcess:pid withReply:^(mach_error_t error) {
//            // NSLog(@"Finished  %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundle);
//            reply(0);
//        }];
//    }
//}

- (void)injectProcess:(pid_t)pid {
    [self.proxy injectProcess:pid];
}

- (void)setupMacEnhanceFolder:(void (^)(mach_error_t))reply {
    if (self.proxyConnection) {
        [self.proxyConnection.remoteObjectProxy folderSetup:^(mach_error_t err) {
            reply(0);
        }];
    }
}

- (void)installFramework:(NSString *)frameworkPath atlocation:(NSString *)frameworkDestinationPath withReply:(void (^)(mach_error_t))reply {
    if (self.proxyConnection) {
        [self.proxyConnection.remoteObjectProxy installFramework:frameworkPath atlocation:frameworkDestinationPath withReply:^(mach_error_t err) {
            reply(0);
        }];
    }
}

@end
