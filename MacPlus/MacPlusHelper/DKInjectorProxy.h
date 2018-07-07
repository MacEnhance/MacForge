//
//  InjectorWrapper.h
//  Dark
//
//  Created by Erwan Barrier on 8/6/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DKInjectorProxy : NSObject

+ (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error;
+ (BOOL)inject:(NSError **)error;

@end
