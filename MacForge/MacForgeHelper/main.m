//
//  main.m
//  MacForge Helper
//
//  Created by Wolfgang Baird on 04/12/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import "MFAppDelegate.h"
#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[]) {
    MFAppDelegate * delegate = [[MFAppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return EXIT_SUCCESS;
//    return NSApplicationMain(argc, (const char **)argv);
}
