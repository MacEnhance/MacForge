//
//  InjectorWrapper.h
//  Dark
//
//  Created by Wolfgang Baird on 8/6/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFInjector.h"

@interface MFInjectorProxy : NSObject

- (BOOL)injectPID:(pid_t)pid :(NSString*)bundlePath :(NSError **)error;
- (BOOL)inject:(NSError **)error;

@end
