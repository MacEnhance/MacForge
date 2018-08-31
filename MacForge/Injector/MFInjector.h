//
//  Injector.h
//  Injector
//
//  Created by Erwan Barrier on 8/8/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

extern dispatch_source_t g_timer_source;

@interface MFInjector : NSObject

- (mach_error_t)inject:(pid_t)pid withBundle:(const char *)bundlePackageFileSystemRepresentation;

@end
