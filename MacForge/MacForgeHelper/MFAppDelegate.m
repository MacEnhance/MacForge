//
//  MFAppDelegate.m
//  MachInjectSample
//
//  Created by Erwan Barrier on 04/12/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

@import Sparkle;

#import "MFAppDelegate.h"
#import "MFInstaller.h"
#import "MFInjectorProxy.h"

#import "SGDirWatchdog.h"

#import "NSBundle+LoginItem.h"

#import "SIMBL.h"
#import "PluginManager.h"
#import <Carbon/Carbon.h>

#include <syslog.h>

@implementation MFAppDelegate

void HandleExceptions(NSException *exception) {
    NSLog(@"The app has encountered an unhandled exception: %@", [exception debugDescription]);
    // Save application data on crash
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText:exception.name];
    [alert setInformativeText:exception.reason];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

//- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
//    NSAlert *alert = [[NSAlert alloc] init];
//    [alert setMessageText:@"Are you sure you want to quit? If you do plugins will no longer be loaded into Applications."];
//    [alert addButtonWithTitle:@"Cancel"];
//    [alert addButtonWithTitle:@"OK"];
//
////    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
////    [input setStringValue:@"Yolo!"];
////    [alert setAccessoryView:input];
//
//    NSInteger button = [alert runModal];
//    NSApplicationTerminateReply terminator = NSTerminateNow;
//    if (button == NSAlertFirstButtonReturn) {
//        terminator = NSTerminateCancel;
////        [input validateEditing];
//    } else if (button == NSAlertSecondButtonReturn) {
//    } else {
//    }
//
//    return terminator;
//}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSError *error;
    NSSetUncaughtExceptionHandler(&HandleExceptions);
    
//    [MFInstaller install:&error];
    
    // Make sure helpers are installed
    if ([MFInstaller isInstalled] == NO && [MFInstaller install:&error] == NO) {
        assert(error != nil);
        NSLog(@"Couldn't install MachInjectSample (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }
    
    // Check for args so we can run as a command line tool
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if (args.count > 1) {
        Boolean cmd = false;
        NSInteger index;
        // Inject into a bundle
        if ([args containsObject:@"-i"]) {
            cmd = true;
            index = [args indexOfObject:@"-i"] + 1;
            if (args.count > index) {
                NSString *bundleID = [args objectAtIndex:index];
                if (bundleID.length > 0)
                    [MFAppDelegate injectOneProc:bundleID];
            }
        }

        if ([args containsObject:@"-u"]) {
            cmd = true;
            [[PluginManager sharedInstance] checkforPluginUpdatesAndInstall:nil];
        }

        if (cmd) [NSApp terminate:nil];
    }

    [self setupApplication];
    [self watchForPlugins];
}

- (void)setupApplication {
    [self setupMenuItem];
        
    // Start a timer to do daily plugin checks 86400 seconds in a day
    [NSTimer scheduledTimerWithTimeInterval:86400 target:self selector:@selector(checkForPluginUpdates) userInfo:nil repeats:NO];
    
    // Do a plugin check when we launch
    [self checkForPluginUpdates];
    
    // Watch for app launches using CarbonEventHandler, this catches apps like the Dock and com.apple.appkit.xpc.openAndSavePanelService
    // Which are not logged with NSWorkspaceDidLaunchApplicationNotification
    [MFAppDelegate watchForApplications];
    
    // Try injecting into all runnning process in NSWorkspace.sharedWorkspace
    [MFAppDelegate injectAllProc];
}

- (void)checkForPluginUpdates {
    CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
    Boolean autoUpdatePlugins = CFPreferencesGetAppBooleanValue(CFSTR("prefPluginCheck"), CFSTR("com.w0lf.MacForge"), NULL);
    Boolean autoCheckPlugins = CFPreferencesGetAppBooleanValue(CFSTR("prefPluginUpdate"), CFSTR("com.w0lf.MacForge"), NULL);
    if (autoCheckPlugins && !autoUpdatePlugins)
        [self updatesPlugins];
    if (autoUpdatePlugins)
        [self updatesPluginsInstall];
}

- (void)updatesPlugins {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PluginManager sharedInstance] checkforPluginUpdates:nil];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"check"];
    });
}

- (void)updatesPluginsInstall {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PluginManager sharedInstance] checkforPluginUpdatesAndInstall:nil];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"check"];
    });
}

- (void)openAppWithArgs:(NSString*)app :(NSArray*)args {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *url = [NSURL fileURLWithPath:[workspace fullPathForApplication:app]];
    NSError *error = nil;
    [workspace launchApplicationAtURL:url
                              options:0
                        configuration:[NSDictionary dictionaryWithObject:args forKey:NSWorkspaceLaunchConfigurationArguments]
                                error:&error];
}

- (void)toggleStartAtLogin:(id)sender {
    Boolean startsAtLogin = NSBundle.mainBundle.isLoginItemEnabled;
    if (startsAtLogin)
        [[NSBundle mainBundle] disableLoginItem];
    else
        [[NSBundle mainBundle] enableLoginItem];
    [(NSMenuItem*)sender setState:!startsAtLogin];
}

- (void)openMacPlus {
    [self openAppWithArgs:@"MacForge" :@[]];
}

- (void)openMacPlusManage {
    [self openAppWithArgs:@"MacForge" :@[@"manage"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"manage"];
}

- (void)openMacPlusPrefs {
    [self openAppWithArgs:@"MacForge" :@[@"prefs"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"prefs"];
}

- (void)openMacPlusAbout {
    [self openAppWithArgs:@"MacForge" :@[@"about"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"about"];
}

- (void)sendFeedback {
//    [DevMateKit showFeedbackDialog:nil inMode:DMFeedbackDefaultMode];
}

- (void)checkMacPlusForUpdates {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacForge"]];
    NSString* mainapp= [NSBundle mainBundle].bundlePath;
    for (int i = 0; i < 4; i++)
        mainapp = [mainapp stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:mainapp])
        if ([mainapp containsString:@"MacForge.app"])
            GUIBundle = [NSBundle bundleWithPath:mainapp];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
    NSLog(@"MacForgeHelper : GUIDefaults - %@", GUIDefaults);
    if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue]) {
        [myUpdater setAutomaticallyChecksForUpdates:true];
        [myUpdater setAutomaticallyDownloadsUpdates:true];
    }
    NSLog(@"MacForgeHelper : Checking for updates...");
    [myUpdater checkForUpdates:nil];
}

- (void)checkMacPlusForUpdatesBackground {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacForge"]];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
    NSLog(@"MacForgeHelper : GUIDefaults - %@", GUIDefaults);
    if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue]) {
        [myUpdater setAutomaticallyChecksForUpdates:true];
        [myUpdater setAutomaticallyDownloadsUpdates:true];
    }
    if ([[GUIDefaults objectForKey:@"SUEnableAutomaticChecks"] boolValue]) {
        NSLog(@"MacForgeHelper : Checking for updates...");
        [myUpdater checkForUpdatesInBackground];
    }
}

- (void)addMenuItemToMenu:(NSMenu*)menu :(NSString*)title :(SEL)selector :(NSString*)key {
    NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:title action:selector keyEquivalent:key];
    [menu addItem:newItem];
}

- (void)setupMenuItem {
    NSMenu *stackMenu = [[NSMenu alloc] initWithTitle:@"MacForge"];
    [self addMenuItemToMenu:stackMenu :@"Manage Plugins" :@selector(openMacPlusManage) :@""];
    [self addMenuItemToMenu:stackMenu :@"Preferences..." :@selector(openMacPlusPrefs) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Open at Login" :@selector(toggleStartAtLogin:) :@""];
    [[stackMenu itemAtIndex:3] setState:NSBundle.mainBundle.isLoginItemEnabled];
//    [self addMenuItemToMenu:stackMenu :@"Show menubar item" :@selector(sendFeedback) :@""];
//    [[stackMenu itemAtIndex:4] setState:NSBundle.mainBundle.isLoginItemEnabled];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Open MacForge" :@selector(openMacPlus) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Update Plugins..." :@selector(updatesPluginsInstall) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Check for Updates..." :@selector(checkMacPlusForUpdates) :@""];
    [self addMenuItemToMenu:stackMenu :@"About MacForge" :@selector(openMacPlusAbout) :@""];
    [self addMenuItemToMenu:stackMenu :@"Quit" :@selector(terminate:) :@""];
    _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBar setMenu:stackMenu];
    [_statusBar setTitle:@""];
    NSImage *statusImage = [NSImage imageNamed:@"menu.icns"];
    [statusImage setTemplate:true];
    [statusImage setSize:NSMakeSize(20, 20)];
    [_statusBar setImage:statusImage];
}

/*
 Watch for application launches using NSWorkspace
 Not currently used
*/
+ (void)startWatching {
    NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification * _Nonnull note) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        NSRunningApplication *app = [note.userInfo valueForKey:NSWorkspaceApplicationKey];
                                        [MFAppDelegate injectBundle:app];
                                    });
                                }];
}

// Check if a bundle should be injected into specified running application
+ (Boolean)shouldInject:(NSRunningApplication*)runningApp {
    // Abort if you're running something other than macOS 10.X.X
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion);
        return false;
    }
    
    // Don't inject into ourself
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:runningApp.bundleIdentifier]) return false;
    
    // Hardcoded blacklist
    if ([@[@"com.w0lf.MacForge", @"com.w0lf.MacForgeHelper"] containsObject:runningApp.bundleIdentifier]) return false;
    
    // Don't inject if somehow the executable doesn't seem to exist
    if (!runningApp.executableURL.path.length) return false;
    
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
    if (runningApp.bundleURL)
        if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return false;
    
    // User Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil && [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return false;
    }
    
    // System item Inject
    if (runningApp.executableURL.path.pathComponents > 0)
        if ([runningApp.executableURL.path.pathComponents[1] isEqualToString:@"System"]) SIMBLLogDebug(@"injecting into system process");
    
    return true;
}

// Try injecting all valid bundles into an running application
+ (void)injectBundle:(NSRunningApplication*)runningApp {
    // Check if there is anything valid to inject
    if ([MFAppDelegate shouldInject:runningApp]) {
        pid_t pid = [runningApp processIdentifier];
        // Try injecting each valid plugin into the application
        for (NSString *bundlePath in [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]]) {
            NSError *error;
            if ([MFInjectorProxy injectPID:pid :bundlePath :&error] == false) {
                assert(error != nil);
                SIMBLLogNotice(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
            }
        }
    }
}

// Try injecting all valid bundles into an application based on bundle ID
+ (void)injectOneProc:(NSString*)bundleID {
    // List of all runnning applications with specific bundle ID
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
    
    // Try to inject each item with all valid bundles
    for (NSRunningApplication *runningApp in apps)
        [MFAppDelegate injectBundle:runningApp];
}

// Try injecting one specific bundle into all running applications
+ (void)injectOneBundle:(NSString*)bundlePath {
    // List of all runnning applications
    for (NSRunningApplication *runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        // Check if the specified bundle should load into the application
        if ([MFAppDelegate shouldInject:runningApp]) {
            pid_t pid = [runningApp processIdentifier];
            NSError *error;
            // Inject the bundle
            if ([MFInjectorProxy injectPID:pid :bundlePath :&error] == false) {
                assert(error != nil);
                SIMBLLogNotice(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
            }
        }
    }
}

// Try injecting all valid bundles into all running applications
+ (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [MFAppDelegate injectBundle:app];
}

// Set up a watcher to automatically load plugins if they're manually placed in one of the valid plugin folders
// Set up a watcher to automatically quit if the main app is trashed
- (void)watchForPlugins {
    watchdogs = [[NSMutableArray alloc] init];
    
    // Trash watcher
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path update:^{ [MFAppDelegate abortMission]; }];
    [watchDog start];
    [watchdogs addObject:watchDog];
    
    // Plugin watcher
    for (NSString *path in [PluginManager MacEnhancePluginPaths]) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path update:^{ [MFAppDelegate injectAllProc]; }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

// Close and offer to uninstall if main application is trashed while running
+ (void)abortMission {
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    
    // See if a copy of MacForge is in the trash
    if ([[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil] containsObject:@"MacForge.app"]) {
        
        // See if our original bundle path still exists
        if (![NSFileManager.defaultManager fileExistsAtPath:NSBundle.mainBundle.bundlePath]) {
//            NSString *param = [NSString stringWithFormat:@"echo %@ > ~/Desktop/abcdef.txt", NSBundle.mainBundle.bundlePath];
//            system([param UTF8String]);
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"We noticed you threw MacForge in the Trash. Would you like to quit the helper and uninstall?"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert addButtonWithTitle:@"OK"];
            NSInteger button = [alert runModal];
            if (button == NSAlertFirstButtonReturn) {
               //        [input validateEditing];
            } else if (button == NSAlertSecondButtonReturn) {
               [NSApp terminate:nil];
            } else {
            }
        }
        
    }
}

// Setup Carbon Event handler to watch for application launches
+ (void)watchForApplications {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated }
    };
    if (sCarbonEventsRef == NULL) {
        (void) InstallEventHandler(GetApplicationEventTarget(), (EventHandlerUPP) CarbonEventHandler, GetEventTypeCount(kEvents), kEvents, (__bridge void *)(self), &sCarbonEventsRef);
    }
}

// Inject into launched applications
static OSStatus CarbonEventHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void* inUserData) {
    pid_t pid;
    (void) GetEventParameter(inEvent, kEventParamProcessID, typeKernelProcessID, NULL, sizeof(pid), NULL, &pid);
    switch ( GetEventKind(inEvent) ) {
        case kEventAppLaunched:
            // App lauched!
            [MFAppDelegate injectBundle:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]];
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
