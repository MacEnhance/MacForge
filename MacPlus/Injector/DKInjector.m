//
//  Injector.m
//  Dark
//
//  Created by Erwan Barrier on 8/8/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import "mach_inject_bundle.h"
#import <mach/mach_error.h>

#import "DKInjector.h"

@implementation DKInjector

- (mach_error_t)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation {
  // Disarm timer while installing framework
  dispatch_source_set_timer(g_timer_source, DISPATCH_TIME_FOREVER, 0llu, 0llu);

  mach_error_t error = mach_inject_bundle_pid(bundlePackageFileSystemRepresentation, pid);
  
  // Rearm timer
  dispatch_time_t t0 = dispatch_time(DISPATCH_TIME_NOW, 5llu * NSEC_PER_SEC);
  dispatch_source_set_timer(g_timer_source, t0, 0llu, 0llu);

  return (error);
}

@end
