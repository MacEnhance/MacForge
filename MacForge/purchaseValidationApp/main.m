//
//  main.m
//  purchaseValidationApp
//
//  Created by Wolfgang Baird on 9/20/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"
#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[]) {
    AppDelegate * delegate = [[AppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return EXIT_SUCCESS;
//    @autoreleasepool {
//        // Setup code that might create autoreleased objects goes here.
//    }
//    return NSApplicationMain(argc, argv);
}
