//
//  MFAppDelegate.h
//  MFAppDelegate
//
//  Created by Wolfgang Baird on 04/12/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFAppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate> {
    AuthorizationRef _authRef;
    NSMutableArray   *watchdogs;
}

@property (strong, nonatomic) NSStatusItem *statusBar;
@property (assign) IBOutlet NSWindow *window;

@end
