//
//  main.m
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
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
