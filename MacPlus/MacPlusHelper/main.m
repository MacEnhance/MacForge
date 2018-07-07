//
//  main.m
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import "DKAppDelegate.h"
#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[]) {
    DKAppDelegate * delegate = [[DKAppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return EXIT_SUCCESS;
//    return NSApplicationMain(argc, (const char **)argv);
}
