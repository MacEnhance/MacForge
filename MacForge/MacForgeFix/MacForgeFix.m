//
//  MacForgeFix.m
//  MacForgeFix
//
//  Created by Wolfgang Baird on 7/6/18.
//Copyright © 2018 Erwan Barrier. All rights reserved.
//

#import "MacForgeFix.h"
#import "ZKSwizzle/ZKSwizzle.h"

@interface MacForgeFix()

@end


@implementation MacForgeFix

// Return the single static instance of the plugin object
+ (instancetype)sharedInstance {
    static MacForgeFix *plugin = nil;
    @synchronized(self) {
        if (!plugin) {
            plugin = [[self alloc] init];
        }
    }
    return plugin;
}


// Called when the plugin loads
+ (void)load {
    MacForgeFix *plugin = [MacForgeFix sharedInstance];
    Boolean loaded = false;
    
    // Terminal
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Terminal"]) {
        loaded = true;
        BOOL addWin = true;
        // Check if a window is loaded
        for (NSObject *o in [NSApp windows])
            if ([[o className] isEqualToString:@"TTWindow"])
                addWin = false;
        
        // Add a window by mimicing the keyboard shortcut to open a new window
        if (addWin) {
            CGEventFlags flags = kCGEventFlagMaskCommand;
            CGEventRef ev;
            CGEventSourceRef source = CGEventSourceCreate (kCGEventSourceStateCombinedSessionState);
            
            //press down
            ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)0x2D, true);
            CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags
            CGEventPost(kCGHIDEventTap,ev);
            CFRelease(ev);
            
            //press up
            ev = CGEventCreateKeyboardEvent (source, (CGKeyCode)0x2D, false);
            CGEventSetFlags(ev,flags | CGEventGetFlags(ev)); //combine flags
            CGEventPost(kCGHIDEventTap,ev);
            CFRelease(ev);
            
            CFRelease(source);
        }
    }
    
    // Archive Utility
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.archiveutility"]) {
        loaded = true;
        ZKSwizzle(wb_msf_BAHController, BAHController);
    }
    
    if (loaded) NSLog(@"%@ loaded into %@ on macOS %@", [self class], NSBundle.mainBundle.bundleIdentifier, NSProcessInfo.processInfo.operatingSystemVersionString);
}

@end

@implementation wb_msf_BAHController

// Why is this broken by MacForge loading?
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end
