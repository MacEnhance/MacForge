//
//  MFAppDelegate.h
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableArray *watchdogs;
}

@property (strong, nonatomic) NSStatusItem *statusBar;
@property (assign) IBOutlet NSWindow *window;

@end
