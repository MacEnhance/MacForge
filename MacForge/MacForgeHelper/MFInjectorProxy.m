//
//  InjectorWrapper.m
//  Dark
//
//  Created by Wolfgang Baird on 8/6/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <mach/mach_error.h>

#import "MFInstaller.h"
#import "MFInjectorProxy.h"

@interface MFInjectorProxy ()
@property (atomic, strong, readwrite) NSXPCConnection *proxyConnection;
@end

@implementation MFInjectorProxy

- (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error {
    //NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Injector.mach" host:nil];
    
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
        
    } else {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Okay"];
            [alert addButtonWithTitle:@"Re-Install"];
            [alert setMessageText:@"Error"];
            [alert setInformativeText:@"MacForge Injection Helper not found!"];
            [alert setAlertStyle:NSAlertStyleWarning];
            NSInteger button = [alert runModal];
            if (button == NSAlertFirstButtonReturn) {
                NSLog(@"Okay");
            } else if (button == NSAlertSecondButtonReturn) {
                NSLog(@"Install");
                NSError *error;
                if ([MFInstaller install:&error] == NO) {
                    NSLog(@"Couldn't install MachInject Sample (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert runModal];
                }
            } else {
                NSLog(@"Hmmm");
            }
        });
        return NO;
    }
}

- (BOOL)inject:(NSError **)error {
    
    pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"]
                  lastObject] processIdentifier];
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Payload" ofType:@"bundle"];
    NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
    NSLog(@"Injecting %@ (%@) with %@", appName, [NSNumber numberWithInt:pid], bundlePath);
    
    __block mach_error_t err = 0;
    [[self.proxyConnection remoteObjectProxy] inject:pid
                                          withBundle:[bundlePath fileSystemRepresentation]
                                           withReply:^(mach_error_t error){ err = error; }];
    
    if (err == 0) {
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


@end
