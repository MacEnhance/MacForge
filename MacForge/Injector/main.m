//
//  main.m
//  Injector
//
//  Created by Wolfgang Baird on 8/7/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
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
