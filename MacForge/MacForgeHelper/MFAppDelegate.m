//
//  MFAppDelegate.m
//  MFAppDelegate
//
//  Created by Wolfgang Baird on 04/12/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

@import Sparkle;

#import "MFAppDelegate.h"
#import "MFInjectorProxy.h"

#import "SGDirWatchdog.h"
#import "NSBundle+LoginItem.h"
#import "SIMBL.h"

#import "MF_PluginManager.h"

#import <Carbon/Carbon.h>
#include <syslog.h>

static MFAppDelegate *mfAppDelegate;

@interface MFAppDelegate ()
@property (strong, atomic) MFInjectorProxy *injectorProxy;
@property Boolean disableInjection;
@end

@implementation MFAppDelegate

void HandleExceptions(NSException *exception) {
    NSLog(@"The app has encountered an unhandled exception: %@", [exception debugDescription]);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.macenhance.MacForgeNotify" object:@"update"];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSSetUncaughtExceptionHandler(&HandleExceptions);
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"];
    if (![[GUIDefaults objectForKey:@"prefHideMenubar"] boolValue])
        [self setupMenuItem];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //
    mfAppDelegate = self;
    
    // Setup injector proxy
    self.injectorProxy = [MFInjectorProxy new];

    // Make sure injector is updated
    NSError *err;
    if (![self isInjectorUpated])
        [self install:&err];

    // Install frameworks and setup plugin folder
    [self giveFramework];
    [self givePluginFldr];

    // Listen for notification to hide/show menubar
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.macenhance.MacForgeHelperNotify" object:nil queue:nil usingBlock:^(NSNotification *notification) {
       dispatch_async(dispatch_get_main_queue(), ^{
           if ([notification.object isEqualToString:@"showMenu"]) [self setupMenuItem];
           if ([notification.object isEqualToString:@"hideMenu"]) [self goodbyeMenu];
       });
    }];

    // Start a timer to do daily plugin and app  update checks 86400 seconds in a day
    [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(checkForPluginUpdates) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(checkMacForgeForUpdatesBackground) userInfo:nil repeats:YES];

    // Watch for new plugins
    [self watchForPlugins];

    // Watch for app launches
    [self watchForApplications];

    // Try injecting into all runnning process in NSWorkspace.sharedWorkspace
    [self injectAllProc];
}

- (BOOL)blessHelperWithLabel:(NSString *)label error:(NSError **)errorPtr {
    BOOL result = NO;
    NSError * error = nil;

    AuthorizationItem authItem        = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights    = { 1, &authItem };
    AuthorizationFlags flags          = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
                                        kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    /* Obtain the right to install our privileged helper tool (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCopyRights(self->_authRef, &authRights, kAuthorizationEmptyEnvironment, flags, NULL);
    if (status != errAuthorizationSuccess) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    } else {
        CFErrorRef  cfError;
        /* This does all the work of verifying the helper tool against the application and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The executable is placed in /Library/PrivilegedHelperTools. */
        result = (BOOL) SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, _authRef, &cfError);
        if (!result) {
            error = CFBridgingRelease(cfError);
        }
    }
    if ( ! result && (errorPtr != NULL) ) {
        assert(error != nil);
        *errorPtr = error;
    }
    
    return result;
}

- (BOOL)install:(NSError **)error {
    BOOL result = 1;
       
    OSStatus status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &_authRef);
    if (status != errAuthorizationSuccess) {
        /* AuthorizationCreate really shouldn't fail. */
        _authRef = NULL;
    }

    if (![self blessHelperWithLabel:@"com.macenhance.MacForge.Injector" error:error]) {
        NSLog(@"Something went wrong! %@ / %d", [*error domain], (int) [*error code]);
    } else {
        NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:MFUserDefaultsInstalledVersionKey];
        NSLog(@"Job is available! Installed v%@", currentVersion);
        self.injectorProxy = [MFInjectorProxy new];
        
        // Install frameworks, setup plugin folder and inject
        [self giveFramework];
        [self givePluginFldr];
        [self injectAllProc];
    }
  
    return result;
}

- (BOOL)isBlessed {
    // No injector PrivilegedHelperTool found
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.macenhance.MacForge.Injector"])
        return false;
    
    // No injector LaunchDaemons found
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchDaemons/com.macenhance.MacForge.Injector.plist"])
        return false;
    
    return true;
}

- (void)giveFramework {
    // No mach_inject_bundle found
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Frameworks/mach_inject_bundle.framework"])
        [self.injectorProxy installMachInjectBundleFramework:&error];
    
    // No menubar framework found
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Contents/Frameworks/MenuBar.framework", NSBundle.mainBundle.bundlePath];
    NSString *destination = @"/Library/Frameworks/MenuBar.framework";
    if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
        [self.injectorProxy installFramework:frameworkPath toLoaction:destination :&error];
        
    frameworkPath = NSBundle.mainBundle.bundlePath;
    frameworkPath = [frameworkPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent stringByAppendingString:@"/Frameworks/Paddle.framework"];
    destination = @"/Library/Frameworks/Paddle.framework";
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkPath])
        if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
            [self.injectorProxy installFramework:frameworkPath toLoaction:destination :&error];
}

- (void)givePluginFldr {    
    Boolean createFolders = false;
    NSArray *paths = @[@"/Library/Application Support/MacEnhance/Plugins", @"/Library/Application Support/MacEnhance/Plugins (Disabled)",
                       @"/Library/Application Support/MacEnhance/Preferences", @"/Library/Application Support/MacEnhance/Themes"];
    for (NSString *path in paths) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
            createFolders = true;
    }
    if (createFolders) {
        NSError *error;
        [self.injectorProxy setupPluginFolder:&error];
    }
}

- (BOOL)isInjectorUpated {
    NSString *versionInstalled = [[NSUserDefaults standardUserDefaults] stringForKey:MFUserDefaultsInstalledVersionKey];
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (![self isBlessed])
        return false;
    // Installed version matches current version
    if ([currentVersion compare:versionInstalled] == NSOrderedSame)
        return true;
    return false;
}

- (void)checkForPluginUpdates {
    CFPreferencesAppSynchronize(CFSTR("com.macenhance.MacForge"));
    Boolean autoUpdatePlugins = CFPreferencesGetAppBooleanValue(CFSTR("prefPluginUpdate"), CFSTR("com.macenhance.MacForge"), NULL);
    if (autoUpdatePlugins) {
        [self updatesPluginsInstall];
    } else {
        [self updatesPlugins];
    }
}

- (void)updatesPlugins {
    [MF_PluginManager.sharedInstance checkforPluginUpdates:nil];
}

- (void)updatesPluginsInstall {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[MF_PluginManager sharedInstance] checkforPluginUpdatesAndInstall:nil];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.macenhance.MacForgeNotify" object:@"check"];
    });
}

- (void)openAppWithArgs:(NSString*)app :(NSArray*)args {
    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.macenhance.MacForge"].count == 0) {
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        NSURL *url = [NSURL fileURLWithPath:[workspace fullPathForApplication:app]];
        NSError *error = nil;
        [workspace launchApplicationAtURL:url
                                  options:0
                            configuration:[NSDictionary dictionaryWithObject:args forKey:NSWorkspaceLaunchConfigurationArguments]
                                    error:&error];
    } else {
        [NSDistributedNotificationCenter.defaultCenter postNotificationName:@"com.macenhance.MacForgeNotify" object:args[0] userInfo:nil deliverImmediately:true];
    }
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
}

- (void)openMacForgePrefs {
    [self openAppWithArgs:@"MacForge" :@[@"prefs"]];
}

- (void)openMacForgeAbout {
    [self openAppWithArgs:@"MacForge" :@[@"about"]];
}

- (void)checkMacForgeForUpdates {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.macenhance.MacForge"]];
    NSString* mainapp= [NSBundle mainBundle].bundlePath;
    for (int i = 0; i < 4; i++)
        mainapp = [mainapp stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:mainapp])
        if ([mainapp containsString:@"MacForge.app"])
            GUIBundle = [NSBundle bundleWithPath:mainapp];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"];
//    NSLog(@"MacForgeHelper : GUIDefaults - %@", GUIDefaults);
    if (![[GUIDefaults objectForKey:@"SUHasLaunchedBefore"] boolValue]) {
        [myUpdater setAutomaticallyChecksForUpdates:true];
        [myUpdater setAutomaticallyDownloadsUpdates:true];
    }
    NSLog(@"MacForgeHelper : Checking for updates...");
    [myUpdater checkForUpdates:nil];
}

- (void)checkMacForgeForUpdatesBackground {
    NSBundle *GUIBundle = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.macenhance.MacForge"]];
    SUUpdater *myUpdater = [SUUpdater updaterForBundle:GUIBundle];
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"];
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
//    NSArray *arguments = [NSArray arrayWithObjects:@"-c", @"ps -A | grep -m1 Console | awk '{print $1}'", nil];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", @"ps aux | grep \"(NotificationCent)\" | grep -v grep | awk '{print $2}' | head -n 1", nil];
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
    [self.injectorProxy injectPID:pid :@"/Library/Application Support/MacEnhance/Plugins/Notifica.bundle" :&error];

    NSLog(@"%@", error);
}

- (NSImage *)imageTint:(NSImage*)img withColor:(NSColor *)tint {
    NSImage *image = img.copy;
    [image setTemplate:false];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceIn);
        [image unlockFocus];
    }
    return image;
}

- (void)colorStatusIconApplyPrefs:(NSMenuItem*)sender {
    NSDictionary *GUIDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"];
    Boolean doColor = [[GUIDefaults valueForKey:@"prefColorMenuBar"] boolValue];
    
    if (sender) {
        doColor = !doColor;
        [sender setState:doColor];
        [GUIDefaults setValue:[NSNumber numberWithBool:doColor] forKey:@"prefColorMenuBar"];
        [[NSUserDefaults standardUserDefaults] setPersistentDomain:GUIDefaults forName:@"com.macenhance.MacForge"];
    }
    
    if (@available(macOS 10.14, *)) {
        if (doColor) {
            
            NSImage *image = [NSImage imageNamed:@"Menubar18"];
            _statusBar.button.contentTintColor = nil;
            [_statusBar.button.image setTemplate:false];
            _statusBar.button.image = [self imageTint:image withColor:NSColor.controlAccentColor];
            
            
        } else {
            
            NSImage *image = [NSImage imageNamed:@"Menubar18"];
            [image setTemplate:true];
            _statusBar.button.contentTintColor = nil;
            _statusBar.button.image = image;
            
        }
    }
}

- (void)disableInject:(NSMenuItem*)item {
    if (item) {
        [item setState:!item.state];
        _disableInjection = item.state;
    }
}

- (void)goodbyeMenu {
    [NSStatusBar.systemStatusBar removeStatusItem:_statusBar];
}

- (void)setupMenuItem {
    NSMenu *stackMenu = [[NSMenu alloc] initWithTitle:@"MacForge"];
    [self addMenuItemToMenu:stackMenu :@"Open at Login" :@selector(toggleStartAtLogin:) :@""];
    [[stackMenu itemAtIndex:0] setState:NSBundle.mainBundle.isLoginItemEnabled];
    [self addMenuItemToMenu:stackMenu :@"Color Menubar Icon" :@selector(colorStatusIconApplyPrefs:) :@""];
    Boolean doColor = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"] valueForKey:@"prefColorMenuBar"] boolValue];
    [[stackMenu itemAtIndex:1] setState:doColor];
    [self addMenuItemToMenu:stackMenu :@"Hide Menubar Icon" :@selector(goodbyeMenu) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Disable Injection" :@selector(disableInject:) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Manage Bundles" :@selector(openMacForgeManage) :@""];
    [self addMenuItemToMenu:stackMenu :@"Update Bundles..." :@selector(updatesPluginsInstall) :@""];
//    [self addMenuItemToMenu:stackMenu :@"Test inject..." :@selector(testInject) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Check for Updates..." :@selector(checkMacForgeForUpdates) :@""];
    [self addMenuItemToMenu:stackMenu :@"MacForge Preferences..." :@selector(openMacForgePrefs) :@""];
    [self addMenuItemToMenu:stackMenu :@"About MacForge" :@selector(openMacForgeAbout) :@""];
    [self addMenuItemToMenu:stackMenu :@"Quit" :@selector(terminate:) :@""];
    _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBar setMenu:stackMenu];
    [_statusBar setTitle:@""];
    [self colorStatusIconApplyPrefs:nil];
}

// Check if a bundle should be injected into specified running application
+ (Boolean)shouldInject:(NSRunningApplication*)runningApp {
    // Don't inject into ourself
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:runningApp.bundleIdentifier]) return false;
    
    // Hardcoded blacklist
    if ([@[@"com.macenhance.MacForge", @"com.macenhance.MacForgeHelper"] containsObject:runningApp.bundleIdentifier]) return false;
    
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

- (NSString*)runScript:(NSString*)script {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", script];
    task.standardOutput = pipe;
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

- (Boolean)xcodeAttached:(pid_t)pid {
    NSString *script = [NSString stringWithFormat:@"lsof -p %d | grep \'/Applications/.*/Contents/Developer/usr/lib/libMainThreadChecker.dylib\'", pid];
    NSString *res = [self runScript:script];
    if (res.length > 0)
        return true;
    return false;
}

// Try injecting all valid bundles into an running application
- (void)injectBundle:(NSRunningApplication*)runningApp {
    if (!_disableInjection) {
       if ([MFAppDelegate shouldInject:runningApp]) {
           pid_t pid = [runningApp processIdentifier];
           // Try injecting each valid plugin into the application
                
           // async check if Xcode is attached to process
           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

               Boolean isXcodeRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dt.Xcode"].count;
               Boolean isXcodeAttached = false;
               if (isXcodeRunning)
                   isXcodeAttached = [self xcodeAttached:pid];

               // Do the injecting
               if (!isXcodeAttached) {
                   // make sure we're back on the main thread
                   dispatch_async(dispatch_get_main_queue(), ^{
                       for (NSString *bundlePath in [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]]) {
                           NSError *error;
                           [self.injectorProxy injectPID:pid :bundlePath :&error];
                           if(error) NSLog(@"Couldn't inject into %d : %@ (domain: %@ code: %@)", pid, runningApp.localizedName, error.domain, [NSNumber numberWithInteger:error.code]);
                       }
                   });
               }

           });
       }
    }
}

// Try injecting all valid bundles into an application based on bundle ID
- (void)injectOneProc:(NSString*)bundleID {
    // List of all runnning applications with specific bundle ID
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
    
    // Try to inject each item with all valid bundles
    for (NSRunningApplication *runningApp in apps)
        [self injectBundle:runningApp];
}

// Try injecting one specific bundle into all running applications
- (void)injectOneBundle:(NSString*)bundlePath {
    // List of all runnning applications
    for (NSRunningApplication *runningApp in NSWorkspace.sharedWorkspace.runningApplications) {
        // Check if the specified bundle should load into the application
        if ([MFAppDelegate shouldInject:runningApp]) {
            pid_t pid = [runningApp processIdentifier];
            NSError *error;
            // Inject the bundle
            [self.injectorProxy injectPID:pid :bundlePath :&error];
            if(error) {
                SIMBLLogNotice(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
            }
        }
    }
}

// Try injecting all valid bundles into all running applications
- (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [self injectBundle:app];
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
    for (NSString *path in [MF_PluginManager MacEnhancePluginPaths]) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path update:^{ [self injectAllProc]; }];
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
- (void)watchForApplications {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated },
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
            if(mfAppDelegate)
                [mfAppDelegate injectBundle:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]];
//            NSLog(@"CarbonEventHandler Launching nc : %d : %f", pid, [NSDate timeIntervalSinceReferenceDate] * 1000);
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
