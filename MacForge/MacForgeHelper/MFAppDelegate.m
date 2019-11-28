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

//- (void)userNotificationCenter:(NSUserNotificationCenter *)center
//        didDeliverNotification:(NSUserNotification *)notification {
//
//}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"update"];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSError *error;
    NSSetUncaughtExceptionHandler(&HandleExceptions);
    
    [self setupApplication];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.macenhance.MacForgeHelperNotify"
                                                                 object:nil
                                                                  queue:nil
                                                             usingBlock:^(NSNotification *notification)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([notification.object isEqualToString:@"showMenu"]) [self setupMenuItem];
            if ([notification.object isEqualToString:@"hideMenu"]) [self noStatusIcon];
        });
    }];
    
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

    [self watchForPlugins];
}

- (void)setupApplication {
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
    if (![[GUIDefaults objectForKey:@"prefHideMenubar"] boolValue])
        [self setupMenuItem];
        
    // Start a timer to do daily plugin and app  update checks 86400 seconds in a day
    [NSTimer scheduledTimerWithTimeInterval:86400 target:self selector:@selector(checkForPluginUpdates) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:86400 target:self selector:@selector(checkMacForgeForUpdatesBackground) userInfo:nil repeats:YES];
    
    // Do a plugin and app  update check when we launch
    [self checkForPluginUpdates];
    [self checkMacForgeForUpdatesBackground];
    
    // Watch for app launches using CarbonEventHandler, this catches apps like the Dock and com.apple.appkit.xpc.openAndSavePanelService
    // Which are not logged with NSWorkspaceDidLaunchApplicationNotification
    [MFAppDelegate watchForApplications];
    
    // Try injecting into all runnning process in NSWorkspace.sharedWorkspace
    [MFAppDelegate injectAllProc];
}

- (void)checkForPluginUpdates {
    CFPreferencesAppSynchronize(CFSTR("com.w0lf.MacForge"));
    Boolean autoUpdatePlugins = CFPreferencesGetAppBooleanValue(CFSTR("prefPluginUpdate"), CFSTR("com.w0lf.MacForge"), NULL);
//    Boolean autoCheckPlugins = CFPreferencesGetAppBooleanValue(CFSTR("prefPluginCheck"), CFSTR("com.w0lf.MacForge"), NULL);
//    if (autoCheckPlugins && !autoUpdatePlugins)
//        [self updatesPlugins];
    if (autoUpdatePlugins) {
        [self updatesPluginsInstall];
    } else {
        [self updatesPlugins];
    }
}

- (void)updatesPlugins {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUserNotification *notif = [[PluginManager sharedInstance] checkforPluginUpdatesNotify];
        if (notif) {
            NSUserNotificationCenter.defaultUserNotificationCenter.delegate = self;
            [NSUserNotificationCenter.defaultUserNotificationCenter deliverNotification:notif];
        }
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

- (void)openMacForge {
    [self openAppWithArgs:@"MacForge" :@[]];
}

- (void)openMacForgeManage {
    [self openAppWithArgs:@"MacForge" :@[@"manage"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"manage"];
}

- (void)openMacForgePrefs {
    [self openAppWithArgs:@"MacForge" :@[@"prefs"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"prefs"];
}

- (void)openMacForgeAbout {
    [self openAppWithArgs:@"MacForge" :@[@"about"]];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.w0lf.MacForgeNotify" object:@"about"];
}

- (void)checkMacForgeForUpdates {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacForge"]];
    NSString* mainapp= [NSBundle mainBundle].bundlePath;
    for (int i = 0; i < 4; i++)
        mainapp = [mainapp stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:mainapp])
        if ([mainapp containsString:@"MacForge.app"])
            GUIBundle = [NSBundle bundleWithPath:mainapp];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
//    NSLog(@"MacForgeHelper : GUIDefaults - %@", GUIDefaults);
    if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue]) {
        [myUpdater setAutomaticallyChecksForUpdates:true];
        [myUpdater setAutomaticallyDownloadsUpdates:true];
    }
    NSLog(@"MacForgeHelper : Checking for updates...");
    [myUpdater checkForUpdates:nil];
}

- (void)checkMacForgeForUpdatesBackground {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacForge"]];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
//    NSLog(@"MacForgeHelper : GUIDefaults - %@", GUIDefaults);
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

- (void)testInject {
    NSError *error;
//    pid_t pid = 12915;
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", @"ps -A | grep -m1 Console | awk '{print $1}'", nil];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    pid_t pid = output.intValue;
    
    NSLog(@"%d", pid);
//    ps -A | grep -m1 SidecarRelay | awk '{print $1}'
    
//    [MFInjectorProxy injectPID:pid :@"/Users/w0lf/Library/Developer/Xcode/DerivedData/poopbutt-edtzriagafrshgeqwfflriaduapq/Build/Products/Debug/libpoopbutt.dylib" :&error];
//    [MFInjectorProxy injectPID:pid :@"/Library/Application Support/MacEnhance/Plugins (Disabled)/Afloat.bundle" :&error];
    [MFInjectorProxy injectPID:86959 :@"/Library/Application Support/MacEnhance/Plugins (Disabled)/Afloat.bundle" :&error];

    NSLog(@"%@", error);
}

- (void)noStatusIconApplyPrefs {
    [self noStatusIcon];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.w0lf.MacForge"];
    [GUIDefaults setValue:[NSNumber numberWithBool:true] forKey:@"prefHideMenubar"];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:GUIDefaults forName:@"com.w0lf.MacForge"];
}

- (void)noStatusIcon {
    [[NSStatusBar systemStatusBar] removeStatusItem:_statusBar];
}

- (void)setupMenuItem {
    NSMenu *stackMenu = [[NSMenu alloc] initWithTitle:@"MacForge"];
    [self addMenuItemToMenu:stackMenu :@"Preferences..." :@selector(openMacForgePrefs) :@""];
    [self addMenuItemToMenu:stackMenu :@"Open at Login" :@selector(toggleStartAtLogin:) :@""];
    [[stackMenu itemAtIndex:1] setState:NSBundle.mainBundle.isLoginItemEnabled];
    [self addMenuItemToMenu:stackMenu :@"Hide Menubar Icon" :@selector(noStatusIconApplyPrefs) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Manage Plugins" :@selector(openMacForgeManage) :@""];
    [self addMenuItemToMenu:stackMenu :@"Update Plugins..." :@selector(updatesPluginsInstall) :@""];
//    [self addMenuItemToMenu:stackMenu :@"Test inject..." :@selector(testInject) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Check for Updates..." :@selector(checkMacForgeForUpdates) :@""];
    [self addMenuItemToMenu:stackMenu :@"About MacForge" :@selector(openMacForgeAbout) :@""];
    [self addMenuItemToMenu:stackMenu :@"Quit" :@selector(terminate:) :@""];
    _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBar setMenu:stackMenu];
    [_statusBar setTitle:@""];
    NSImage *statusImage = [NSImage imageNamed:@"Menubar18"];
    [statusImage setTemplate:true];
    if (@available(macOS 10.14, *)) {
        _statusBar.button.contentTintColor = NSColor.controlAccentColor;
    } else {
        // Fallback on earlier versions
    }
//    [statusImage setSize:NSMakeSize(20, 20)];
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
    if ([@[@"com.w0lf.MacForge", @"com.w0lf.MacForgeHelper", @"com.macenhance.purchaseValidationApp"] containsObject:runningApp.bundleIdentifier]) return false;
    
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
    SIMBLLogDebug(@"App start notification: %@", runningApp);
    
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
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
       // Wait for the app to finish launching
       // Check if there is anything valid to inject
       if ([MFAppDelegate shouldInject:runningApp]) {
           pid_t pid = [runningApp processIdentifier];
           // Try injecting each valid plugin into the application
           for (NSString *bundlePath in [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]]) {
   //            NSLog(@"Try inject App %@", runningApp.bundleIdentifier);

//               dispatch_async(dispatch_get_main_queue(), ^(void){
                   NSError *error;
                   if ([MFInjectorProxy injectPID:pid :bundlePath :&error] == false) {
                        assert(error != nil);
                        NSLog(@"Couldn't inject into %d : %@ (domain: %@ code: %@)", pid, runningApp.localizedName, error.domain, [NSNumber numberWithInteger:error.code]);
                        SIMBLLogNotice(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
                   }
//               });
              
           }
       }
       
//    });
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
            NSLog(@"%d", pid);
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
