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
        self.proxyConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"com.macenhance.MacForge.Injector.mach" options:NSXPCConnectionPrivileged];
        self.proxyConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
        [self.proxyConnection resume];
    }
    return self;
}

- (void)injectBundle:(NSString *)bundle inProcess:(pid_t)pid withReply:(void (^)(mach_error_t))reply {
    if (self.proxyConnection) {
        NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
        NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
        NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundle);
        [self.proxyConnection.remoteObjectProxy injectBundle:bundle.fileSystemRepresentation inProcess:pid withReply:^(mach_error_t error) {
            NSLog(@"Finished  %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundle);
        }];
    }
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

//- (void)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error {
//    if (self.proxyConnection) {
//        NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
//        NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
//        NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
//
//        __block mach_error_t err = 0;
//        [[self.proxyConnection remoteObjectProxy] inject:pid
//                                              withBundle:[bundlePath fileSystemRepresentation]
//                                               withReply:^(mach_error_t error) {
//            err = error;
//
//            NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
//
//        }];
//
//        if (err == 0) {
//            //NSLog(@"Injected %@", appName);
//            return;
//        } else {
//            NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
//            *error = [[NSError alloc] initWithDomain:MFErrorDomain
//                                                code:MFErrInjection
//                                            userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
//
//            return;
//        }
//        return;
//    }
//    return;
//}
//
//- (void)injectPID:(pid_t)pid withBundle:(NSString *)bundlePath withReply:(void (^)(BOOL))reply {
//    if (self.proxyConnection) {
//        NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
//        NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
//        // NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
//        [[self.proxyConnection remoteObjectProxy] inject:pid
//                                              withBundle:[bundlePath fileSystemRepresentation]
//                                               withReply:^(mach_error_t error) {
//            // NSLog(@"Finished injection in %@ (%@) (%@) with result %d", appName, appID, [NSNumber numberWithInt:pid], error);
//            reply(true);
//        }];
//    }
//}
//
//- (BOOL)inject:(NSError **)error {
//    pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"] lastObject] processIdentifier];
//    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"cDock" ofType:@"bundle"];
//    NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
////    NSLog(@"Attempting injecting %@ (%@) with %@", appName, [NSNumber numberWithInt:pid], bundlePath);
//
//    __block mach_error_t err = 0;
//    [[self.proxyConnection remoteObjectProxy] inject:pid
//                                          withBundle:[bundlePath fileSystemRepresentation]
//                                           withReply:^(mach_error_t error){ err = error; }];
//
//    if (err == 0) {
////        NSLog(@"%@ (%@) successfully injected with %@", appName, [NSNumber numberWithInt:pid], bundlePath);
//        return YES;
//    } else {
//        NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
//        *error = [[NSError alloc] initWithDomain:MFErrorDomain
//                                            code:MFErrInjection
//                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
//
//        return NO;
//    }
//}
//
//- (void)setupPluginFolderWithReply:(void (^)(BOOL))reply {
//    if (self.proxyConnection) {
//        [self.proxyConnection.remoteObjectProxy setupMacEnhanceFolder:^(mach_error_t error) {
//            NSLog(@"Hello");
//            reply(true);
//        }];
//    }
//}
//
//- (BOOL)setupPluginFolder:(NSError **)error {
//    __block mach_error_t err = 0;
//    [[self.proxyConnection remoteObjectProxy] setupMacEnhanceFolder:^(mach_error_t error) { err = error; }];
//    if (err == 0) {
//        NSLog(@"Plugin folder successfully created.");
//        return YES;
//    } else {
//        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
//        *error = [[NSError alloc] initWithDomain:MFErrorDomain
//                                            code:MFErrSetup
//                                        userInfo:@{NSLocalizedDescriptionKey: MFErrSetupDescription}];
//        return NO;
//    }
//}
//
//- (BOOL)installMachInjectBundleFramework:(NSError **)error {
//    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Contents/Frameworks/mach_inject_bundle.framework", NSBundle.mainBundle.bundlePath];
//    __block mach_error_t err = 0;
//    [[self.proxyConnection remoteObjectProxy] installFramework:frameworkPath withReply:^(mach_error_t error) { err = error; }];
//    if (err == 0) {
//        NSLog(@"%@", [NSString stringWithFormat:@"Framework %@ successfully installed.", frameworkPath]);
//        return YES;
//    } else {
//        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
//        *error = [[NSError alloc] initWithDomain:MFErrorDomain
//                                            code:MFErrInstallFramework
//                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInstallDescription}];
//        return NO;
//    }
//}
//
//- (BOOL)installFramework:(NSString*)frameworkPath toLoaction:(NSString*)dest :(NSError **)error {
//    __block mach_error_t err = 0;
//    [[self.proxyConnection remoteObjectProxy] installFramework:frameworkPath atlocation:dest withReply:^(mach_error_t error) { err = error; }];
//    if (err == 0) {
//        NSLog(@"%@", [NSString stringWithFormat:@"Framework %@ successfully installed.", frameworkPath]);
//        return YES;
//    } else {
//        //    NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
//        *error = [[NSError alloc] initWithDomain:MFErrorDomain
//                                            code:MFErrInstallFramework
//                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInstallDescription}];
//        return NO;
//    }
//}

@end
