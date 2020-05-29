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
@end

@implementation MFInjectorProxy

- (id)init {
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.proxyConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.w0lf.MacForge.Injector.mach" options:NSXPCConnectionPrivileged];
        self.proxyConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
        [self.proxyConnection resume];
    }
    return self;
}

- (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error {
    if (self.proxyConnection) {
        NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
        //    NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
        //    NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
        
        __block mach_error_t err = 0;
        [[self.proxyConnection remoteObjectProxy] inject:pid
                                              withBundle:[bundlePath fileSystemRepresentation]
                                               withReply:^(mach_error_t error) { err = error; }];
        
        if (err == 0) {
            //NSLog(@"Injected %@", appName);
            return YES;
        } else {
            NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
            *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                                code:MFErrInjection
                                            userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
            
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)inject:(NSError **)error {
    pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"] lastObject] processIdentifier];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"cDock" ofType:@"bundle"];
    NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
    NSLog(@"Attempting injecting %@ (%@) with %@", appName, [NSNumber numberWithInt:pid], bundlePath);
    
    __block mach_error_t err = 0;
    [[self.proxyConnection remoteObjectProxy] inject:pid
                                          withBundle:[bundlePath fileSystemRepresentation]
                                           withReply:^(mach_error_t error){ err = error; }];
    
    if (err == 0) {
        NSLog(@"%@ (%@) successfully injected with %@", appName, [NSNumber numberWithInt:pid], bundlePath);
        NSLog(@"Injected App");
        return YES;
    } else {
        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
        *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                            code:MFErrInjection
                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
        
        return NO;
    }
}

- (BOOL)setupPluginFolder:(NSError **)error {
    __block mach_error_t err = 0;
    [[self.proxyConnection remoteObjectProxy] setupPluginFolderWithReply:^(mach_error_t error) { err = error; }];
    if (err == 0) {
        NSLog(@"Plugin folder successfully created.");
        return YES;
    } else {
        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
        *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                            code:MFErrInjection
                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
        return NO;
    }
}

- (BOOL)installMachInjectBundleFramework:(NSError **)error {
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Contents/Frameworks/mach_inject_bundle.framework", NSBundle.mainBundle.bundlePath];
    __block mach_error_t err = 0;
    [[self.proxyConnection remoteObjectProxy] installFramework:frameworkPath withReply:^(mach_error_t error) { err = error; }];
    if (err == 0) {
        NSLog(@"Framework successfully installed.");
        return YES;
    } else {
        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
        *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                            code:MFErrInjection
                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
        return NO;
    }
}

@end
