//
//  main.m
//  Injector
//
//  Created by Erwan Barrier on 8/7/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MFInjector.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        MFInjector *injector = [MFInjector new];
        [injector run];
    }

  return 0;
}
