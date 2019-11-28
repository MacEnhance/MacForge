//
//  InjectorWrapper.m
//  Dark
//
//  Created by Erwan Barrier on 8/6/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>
#import <mach/mach_error.h>

#import "MFInjector.h"
#import "MFInjectorProxy.h"

@implementation MFInjectorProxy

+ (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error {
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Injector.mach" host:nil];
    assert(c != nil);
    
    MFInjector *injector = (MFInjector *)[c rootProxy];
    assert(injector != nil);
    
    NSString *appName = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
//    NSString *appID = [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier;
//    NSLog(@"Injecting %@ (%@) (%@) with %@", appName, appID, [NSNumber numberWithInt:pid], bundlePath);
    
    mach_error_t err = [injector inject:pid withBundle:[bundlePath fileSystemRepresentation]];
    
    if (err == 0) {
//        NSLog(@"Injected App");
        return YES;
    } else {
//        NSLog(@"an error occurred while injecting %@: %@ (error code: %@)", appName, [NSString stringWithCString:mach_error_string(err) encoding:NSASCIIStringEncoding], [NSNumber numberWithInt:err]);
        *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                            code:MFErrInjection
                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInjectionDescription}];
        
        return NO;
    }
}

+ (BOOL)inject:(NSError **)error {
  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Injector.mach" host:nil];
  assert(c != nil);

  MFInjector *injector = (MFInjector *)[c rootProxy];
  assert(injector != nil);

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
