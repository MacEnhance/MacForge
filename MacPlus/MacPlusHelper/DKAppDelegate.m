//
//  DKAppDelegate.m
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import "DKAppDelegate.h"
#import "DKInstaller.h"
#import "DKInjectorProxy.h"

#import "SIMBL.h"
#import <Carbon/Carbon.h>

#include <syslog.h>

@implementation DKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Check for args so we can run as a command line tool
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    NSLog(@"%@", args);
    
    NSError *error;
    // Install helper tools
    if ([DKInstaller isInstalled] == NO && [DKInstaller install:&error] == NO) {
        assert(error != nil);
        NSLog(@"Couldn't install MachInjectSample (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    
    // [DKAppDelegate startWatching];
    
    // Watch for app launches using CarbonEventHandler, this catches apps like the Dock and com.apple.appkit.xpc.openAndSavePanelService
    // Which are not logged with NSWorkspaceDidLaunchApplicationNotification
    [DKAppDelegate watchForApplications];
    
    // Try injecting into all runnning process in NSWorkspace.sharedWorkspace
    [DKAppDelegate injectAllProc];
}

+ (void)startWatching {
    NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification * _Nonnull note) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        NSRunningApplication *app = [note.userInfo valueForKey:NSWorkspaceApplicationKey];
                                        [DKAppDelegate injectBundle:app];
                                    });
                                }];
}

// Try injecting all valid bundles into an app
+ (void)injectBundle:(NSRunningApplication*)runningApp {
    // Don't inject into ourself
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:runningApp.bundleIdentifier]) return;
    
    // Hardcoded blacklist
    if ([@[] containsObject:runningApp.bundleIdentifier]) return;
    
    // Don't inject if somehow the executable doesn't seem to exist
    if (!runningApp.executableURL.path.length) return;
    
    // If you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    // Log some info about the app
    NSString* appName = runningApp.localizedName;
    SIMBLLogInfo(@"%@ started", appName);
    SIMBLLogDebug(@"app start notification: %@", runningApp);
    
    // Check to see if there are plugins to load
    if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return;
    
    // User Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil && [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return;
    }
    
    // Abort you're running something other than macOS 10.X.X
    if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion);
        return;
    }
    
    // System item Inject
    if (runningApp.executableURL.path.pathComponents > 0)
        if ([runningApp.executableURL.path.pathComponents[1] isEqualToString:@"System"]) SIMBLLogDebug(@"injecting into system process");
    
    pid_t pid = [runningApp processIdentifier];
    for (NSString *bundlePath in [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]]) {
            NSError *error;
            if ([DKInjectorProxy injectPID:pid :bundlePath :&error] == false) {
                assert(error != nil);
                SIMBLLogNotice(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
            }
    }
}

+ (void)injectNewBundle:(NSString*)bundlePath {
    
}

+ (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [DKAppDelegate injectBundle:app];
}

+ (void)watchForApplications {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated }
    };
    if (sCarbonEventsRef == NULL) {
        (void) InstallEventHandler(GetApplicationEventTarget(), (EventHandlerUPP) CarbonEventHandler, GetEventTypeCount(kEvents),
                                   kEvents, (__bridge void *)(self), &sCarbonEventsRef);
    }
}

static OSStatus CarbonEventHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void* inUserData) {
    pid_t pid;
    (void) GetEventParameter(inEvent, kEventParamProcessID, typeKernelProcessID, NULL, sizeof(pid), NULL, &pid);
    switch ( GetEventKind(inEvent) ) {
        case kEventAppLaunched:
            // App lauched!
            // NSLog(@"App launched %@", [NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier);
            [DKAppDelegate injectBundle:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]];
            break;
        case kEventAppTerminated:
            // App terminated!
            break;
        default:
            assert(false);
    }
    return noErr;
}

@end
