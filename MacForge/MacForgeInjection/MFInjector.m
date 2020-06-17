//
//  Injector.m
//  Injector
//
//  Created by Wolfgang Baird on 8/8/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#include <dlfcn.h>
#import "mach_inject.h"
#import "mach_inject_bundle.h"
#import <mach/mach_error.h>

#import "MFInjector.h"

NSString *const MFFrameworkDstPath = @"/Library/Frameworks/mach_inject_bundle.framework";

@interface MFInjector ()
@property (atomic, strong, readwrite) NSXPCListener *listener;
@end

@implementation MFInjector

- (id)init {
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.macenhance.MacForge.Injector.mach"];
        self.listener.delegate = self;
    }
    return self;
}

- (void)run {
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (Boolean)loadMachInject {
    if (![[NSBundle allFrameworks] containsObject:[NSBundle bundleWithPath:MFFrameworkDstPath]]) {
        dlopen("/Library/Frameworks/mach_inject_bundle.framework/mach_inject_bundle", RTLD_LAZY);
        [[NSBundle bundleWithPath:MFFrameworkDstPath] load];
    }
    return [[NSBundle allFrameworks] containsObject:[NSBundle bundleWithPath:MFFrameworkDstPath]];
}

- (void)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation withReply:(void (^)(mach_error_t))reply {
    mach_error_t error = 1337;
    if ([self loadMachInject])
        error = mach_inject_bundle_pid(bundlePackageFileSystemRepresentation, pid);
    reply(error);
}

- (void)inject:(pid_t)pid withLib:(const char *)libraryPath withReply:(void (^)(mach_error_t))reply {
    mach_error_t error = 1337;
    if ([self loadMachInject]) {
        void *module;
        void *bootstrapfn;
        module = dlopen("/Library/PrivilegedHelperTools/bootstrap.dylib",
            RTLD_NOW | RTLD_LOCAL);
        // if(!module)... Kelly, can you handle this?

        bootstrapfn = dlsym(module, "bootstrap");
        //if(!bootstrapfn)... Beyonce, can you handle this?

        error = mach_inject((mach_inject_entry)bootstrapfn, libraryPath, strlen(libraryPath) + 1, pid, 0);
    }
    reply(error);
}

- (void)installFramework:(NSString *)frameworkPath atlocation:(NSString*)frameworkDestinationPath withReply:(void (^)(mach_error_t))reply {
    NSError *fileError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkDestinationPath])
        [[NSFileManager defaultManager] removeItemAtPath:frameworkDestinationPath error:&fileError];
    [[NSFileManager defaultManager] copyItemAtPath:frameworkPath toPath:frameworkDestinationPath error:&fileError];
    mach_error_t error = (int)fileError.code;
    reply(error);
}

- (void)installFramework:(NSString *)frameworkPath withReply:(void (^)(mach_error_t))reply {
    NSError *fileError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:MFFrameworkDstPath])
        [[NSFileManager defaultManager] removeItemAtPath:MFFrameworkDstPath error:&fileError];
    [[NSFileManager defaultManager] copyItemAtPath:frameworkPath toPath:MFFrameworkDstPath error:&fileError];
    mach_error_t error = (int)fileError.code;
    reply(error);
}

- (void)setupPluginFolderWithReply:(void (^)(mach_error_t))reply; {
    NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:0777], NSFilePosixPermissions,
                            [NSNumber numberWithInt:0], NSFileGroupOwnerAccountID,
                            [NSNumber numberWithInt:0], NSFileOwnerAccountID, nil];

    NSError *fileError;
    NSFileManager *man = NSFileManager.defaultManager;
    [man createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Plugins" withIntermediateDirectories:true attributes:attrib error:&fileError];
    [man createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Plugins (Disabled)" withIntermediateDirectories:true attributes:attrib error:&fileError];
    [man createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Preferences" withIntermediateDirectories:true attributes:attrib error:&fileError];
    [man createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Themes" withIntermediateDirectories:true attributes:attrib error:&fileError];
    [man setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Plugins" error:&fileError];
    [man setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Plugins (Disabled)" error:&fileError];
    [man setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Preferences" error:&fileError];
    [man setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Themes" error:&fileError];
    
    mach_error_t error = (int)fileError.code;
    reply(error);
}

#pragma mark XPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    return YES;
}

@end
