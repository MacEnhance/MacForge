//
//  Injector.m
//  Injector
//
//  Created by Erwan Barrier on 8/8/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#include <dlfcn.h>
#import "mach_inject.h"
#import "mach_inject_bundle.h"
#import <mach/mach_error.h>

#import "MFInjector.h"

@interface MFInjector ()
@property (atomic, strong, readwrite) NSXPCListener *listener;
@end

@implementation MFInjector

- (void)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation withReply:(void (^)(mach_error_t))reply {
    mach_error_t error = mach_inject_bundle_pid(bundlePackageFileSystemRepresentation, pid);
    reply(error);
}

- (void)inject:(pid_t)pid withLib:(const char *)libraryPath withReply:(void (^)(mach_error_t))reply {
    void *module;
    void *bootstrapfn;
    module = dlopen("/Library/PrivilegedHelperTools/bootstrap.dylib",
        RTLD_NOW | RTLD_LOCAL);
    // if(!module)... Kelly, can you handle this?

    bootstrapfn = dlsym(module, "bootstrap");
    //if(!bootstrapfn)... Beyonce, can you handle this?

    mach_error_t error = mach_inject((mach_inject_entry)bootstrapfn, libraryPath, strlen(libraryPath) + 1, pid, 0);

    reply(error);
}

- (id)init {
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.w0lf.MacForge.Injector.mach"];
        self.listener.delegate = self;
    }
    return self;
}

- (void)run {
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

#pragma mark XPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

@end
