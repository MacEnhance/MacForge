//
//  InjectorWrapper.m
//  Dark
//
//  Created by Erwan Barrier on 8/6/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <mach/mach_error.h>

#import "MFInstaller.h"
#import "MFInjector.h"
#import "MFInjectorProxy.h"

@implementation MFInjectorProxy

+ (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error {
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Injector.mach" host:nil];
    if (c != nil) {
        [c setReplyTimeout:0.5];
        
        MFInjector *injector = (MFInjector *)[c rootProxy];
    //    assert(injector != nil);
        
        NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
    //    NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
    //    NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
        
        mach_error_t err = [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];
        
        if (err == 0) {
            NSLog(@"Injected %@", appName);
            return YES;
        } else {
            NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
            *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                                code:MFErrInjection
                                            userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
            
            return NO;
        }
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

+ (BOOL)inject:(NSError **)error {
  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Injector.mach" host:nil];
//  assert(c != nil);

  MFInjector *injector = (MFInjector *)[c rootProxy];
//  assert(injector != nil);

  pid_t pid = [[[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.finder"]
                lastObject] processIdentifier];
  
  NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Payload" ofType:@"bundle"];
  NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
  NSLog(@"Injecting %@ (%@) with %@", appName, [NSNumber numberWithInt:pid], bundlePath);

  mach_error_t err = [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];

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

@end
