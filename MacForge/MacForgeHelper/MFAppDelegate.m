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

#import "NSBundle+LoginItem.h"
#import "StartAtLoginController.h"

#import "SGDirWatchdog.h"
#import "SIMBL.h"

// #import "MF_PluginManager.h"

#import <Carbon/Carbon.h>
#include <syslog.h>
#include <sys/sysctl.h>
#include <libproc.h>

static MFAppDelegate *mfAppDelegate;

@interface MFAppDelegate ()
@property (strong, atomic) MFInjectorProxy *injectorProxy;
@property BOOL isARM;
@property Boolean disableInjection;
@property NSMutableArray *currentPlugins;
@end

@implementation MFAppDelegate

void HandleExceptions(NSException *exception) {
    NSLog(@"The app has encountered an unhandled exception: %@", [exception debugDescription]);
}

- (BOOL)isArm64 {
    static BOOL arm64 = NO ;
    static dispatch_once_t once ;
    dispatch_once(&once, ^{
        arm64 = sizeof(int *) == 8 ;
    });
    return arm64;
}

- (void)rediecrLog {
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [[allPaths objectAtIndex:0] stringByAppendingPathComponent:@"MacForge"];
    if (![NSFileManager.defaultManager fileExistsAtPath:appSupport isDirectory:nil])
        [NSFileManager.defaultManager createDirectoryAtPath:appSupport withIntermediateDirectories:true attributes:nil error:nil];
    NSString *pathForLog = [appSupport stringByAppendingPathComponent:@"Injector.log"];
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
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
    
//    ProcessSerialNumber psn = { 0, kNoProcess };
//    while (noErr == GetNextProcess(&psn)) {
//        pid_t pid;
//        if (noErr == GetProcessPID(&psn, &pid)) {
//            char pathBuffer [PROC_PIDPATHINFO_MAXSIZE];
//            proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
//
//            char nameBuffer[256];
//
//            int position = strlen(pathBuffer);
//            while(position >= 0 && pathBuffer[position] != '/') {
//                position--;
//            }
//
//            strcpy(nameBuffer, pathBuffer + position + 1);
//
//            NSLog(@"Process %s (%d)", nameBuffer, pid);
//            // printf("path: %s\n\nname:%s\n\n", pathBuffer, nameBuffer);
//        }
//    }
    
    // Check if we're on ARM processor
    self.isARM = [self isArm64];
    
    // Setup injector proxy
    self.injectorProxy = [MFInjectorProxy new];

    // Make sure injector is updated
    NSError *err;
    if (![self isInjectorUpated])
        [self install:&err];

    // Install frameworks
    [self giveFramework];
    
    // Setup necessary folders and install core plugins
    [self installCorePlugins];

    // Listen for notification to hide/show menubar
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.macenhance.MacForgeHelperNotify" object:nil queue:nil usingBlock:^(NSNotification *notification) {
       dispatch_async(dispatch_get_main_queue(), ^{
           if ([notification.object isEqualToString:@"showMenu"]) [self setupMenuItem];
           if ([notification.object isEqualToString:@"hideMenu"]) [self goodbyeMenu];
       });
    }];

    // Start a timer to do daily plugin and app  update checks 86400 seconds in a day
    NSTimer *updates1 = [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(checkForPluginUpdates) userInfo:nil repeats:YES];
    NSTimer *updates2 = [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(checkMacForgeForUpdatesBackground) userInfo:nil repeats:YES];
    [updates1 fire];
    [updates2 fire];
    
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
        
        // First kill the job in case it already exists
        SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, _authRef, true, &cfError);
        
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
        [self installCorePlugins];
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

// What's this in here for?
- (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int fileSize = 0;

    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
//        NSDictionary *fileDictionary = [[NSFileManager defaultManager] fileAttributesAtPath:[folderPath stringByAppendingPathComponent:fileName] traverseLink:YES];
        fileSize += [fileDictionary fileSize];
    }

    return fileSize;
}

- (void)giveFramework {
    // No menubar framework found
    NSString *frameworkPath = [NSString stringWithFormat:@"%@/Contents/Frameworks/MenuBar.framework", NSBundle.mainBundle.bundlePath];
    NSString *destination = @"/Library/Frameworks/MenuBar.framework";
    if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
        [self.injectorProxy installFramework:frameworkPath atlocation:destination withReply:^(mach_error_t err) { }];
        
    frameworkPath = NSBundle.mainBundle.bundlePath;
    NSString *containerPath = frameworkPath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    
    // Paddle framework not found
    frameworkPath = [containerPath stringByAppendingString:@"/Frameworks/Paddle.framework"];
    destination = @"/Library/Frameworks/Paddle.framework";
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkPath])
        if (![[NSFileManager defaultManager] fileExistsAtPath:destination])
            [self.injectorProxy installFramework:frameworkPath atlocation:destination withReply:^(mach_error_t err) { }];
}

// Install the given bundle from our resources folder to a path
- (void)installBundle:(NSString*)bundle atPath:(NSString*)path {
    NSError *error;
    
    // get the bundle source and destination
    NSString *srcPath = [[NSBundle mainBundle] pathForResource:bundle ofType:@"bundle"];
    NSString *dstPath = [NSString stringWithFormat:@"%@/%@.bundle", path, bundle];
    
    // Get the bundle version strings
    NSString *srcVer = [[[NSBundle bundleWithPath:srcPath] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *dstVer = [[[NSBundle bundleWithPath:dstPath] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    // NSLog(@"MacForgeHelper : Checking bundle...");
    // If the bundle already exists at the destination do a version check
    if ([[NSFileManager defaultManager] fileExistsAtPath:dstPath]) {
        if (![srcVer isEqual:dstVer] && ![srcPath isEqualToString:@""]) {
            NSLog(@"MacForgeHelper : Updating bundle... Destination: %@ > Source: %@", srcVer, dstVer);
            [[NSFileManager defaultManager] removeItemAtPath:@"/tmp/macforge_temp.bundle" error:&error];
            [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:@"/tmp/macforge_temp.bundle" error:&error];
            [[NSFileManager defaultManager] replaceItemAtURL:[NSURL fileURLWithPath:dstPath] withItemAtURL:[NSURL fileURLWithPath:@"/tmp/macforge_temp.bundle"] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:nil error:&error];
        } else {
            NSLog(@"MacForgeHelper : Bundle (%@) is up to date...", bundle);
        }
    } else {
        // No existing bundle so safe to install
        NSLog(@"MacForgeHelper : Installing bundle... %@", srcPath);
        [[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:dstPath error:&error];
    }
}

- (void)installCorePlugins {
    [self.injectorProxy setupMacEnhanceFolder:^(mach_error_t err) {
        // DockKit is currently only needed for Big Sur and above
        [self installBundle:@"DockKit" atPath:@"/Library/Application Support/MacEnhance/CorePlugins"];
        // [self installBundle:@"PluginLoader" atPath:@"/Library/Application Support/MacEnhance/CorePlugins"];
    }];
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
    // [MF_PluginManager.sharedInstance checkforPluginUpdates:nil];
}

- (void)updatesPluginsInstall {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // [[MF_PluginManager sharedInstance] checkforPluginUpdatesAndInstall:nil];
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
        [NSBundle.mainBundle disableLoginItem];
    else
        [NSBundle.mainBundle enableLoginItem];
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
//    NSLog(@"MacForgeHelper : Checking for updates...");
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
//        NSLog(@"MacForgeHelper : Checking for updates...");
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
//    [self.injectorProxy injectPID:pid :@"/Library/Application Support/MacEnhance/Plugins/Notifica.bundle" :&error];

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
    [self addMenuItemToMenu:stackMenu :@"Hide Menubar Icon" :@selector(goodbyeMenu) :@""];
    [[stackMenu itemAtIndex:0] setState:NSBundle.mainBundle.isLoginItemEnabled];
    [self addMenuItemToMenu:stackMenu :@"Preferences..." :@selector(openMacForgePrefs) :@""];
//    [self addMenuItemToMenu:stackMenu :@"Color Menubar Icon" :@selector(colorStatusIconApplyPrefs:) :@""];
//    Boolean doColor = [[[[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.macenhance.MacForge"] valueForKey:@"prefColorMenuBar"] boolValue];
//    [[stackMenu itemAtIndex:1] setState:doColor];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Disable Injection" :@selector(disableInject:) :@""];
//    [self addMenuItemToMenu:stackMenu :@"inject into process" :@selector(testInject) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Manage Bundles" :@selector(openMacForgeManage) :@""];
    [self addMenuItemToMenu:stackMenu :@"Update Bundles..." :@selector(updatesPluginsInstall) :@""];
    [stackMenu addItem:NSMenuItem.separatorItem];
    [self addMenuItemToMenu:stackMenu :@"Check for Updates..." :@selector(checkMacForgeForUpdates) :@""];
    [self addMenuItemToMenu:stackMenu :@"About" :@selector(openMacForgeAbout) :@""];
    [self addMenuItemToMenu:stackMenu :@"Quit" :@selector(terminate:) :@""];
    _statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusBar setMenu:stackMenu];
    [_statusBar.button setTitle:@""];
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
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
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

- (void)startQueuedInject:(NSRunningApplication*)runningApp {
    if (!_disableInjection) {
       if ([MFAppDelegate shouldInject:runningApp]) {
           pid_t pid = [runningApp processIdentifier];
           
           // Probably need a better way to know when it's safe to load without locking the process
           double injectDelay = 0.2;
           
           // Special check for Dock process
           if ([runningApp.bundleIdentifier isEqualToString:@"com.apple.dock"]) {
               NSBundle *bun = [NSBundle bundleWithPath:@"/Library/Application Support/MacEnhance/CorePlugins/DockKit.bundle"];
               // Don't load anything in the Dock if we can't first load DockKit!
               if (!bun) return;
               
               // Load DockKit
               [self.injectorProxy injectBundle:bun.executablePath inProcess:pid withReply:^(mach_error_t error) { }];
           }
           
           // This proc takes a while to get going
           if ([runningApp.bundleIdentifier isEqualToString:@"com.apple.finder"])
               injectDelay = 1.0;
           
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(injectDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               
               // Check for some cases where we don't load
               BOOL shouldLoad = true;
               
               // ARM cpu and process is translated
               if (self.isARM && runningApp.executableArchitecture == 16777223) shouldLoad = false;
               
               // Process has xcode debugger attached to is
               Boolean isXcodeRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dt.Xcode"].count;
               Boolean isXcodeAttached = false;
               if (isXcodeRunning)
                   isXcodeAttached = [self xcodeAttached:pid];
               
               if (isXcodeAttached) shouldLoad = false;

               // Do the injecting
               if (shouldLoad) {
                   
//                   dispatch_async(dispatch_get_main_queue(), ^{
                       
                       NSArray *plugins = [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]];
                       plugins = [plugins sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                       NSLog(@"Started loading bundles into %d", runningApp.processIdentifier);
                       [self queuedInject:runningApp withArray:plugins.mutableCopy];

//                   });
               }
               
           });
           
//           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//           });
       }
    }
}

- (void)queuedInject:(NSRunningApplication*)runningApp withArray:(NSMutableArray*)bundles {
    if (bundles.count == 0) {
        NSLog(@"Finished loading bundles into %d", runningApp.processIdentifier);
        return;
    } else {
        NSBundle *bun = [NSBundle bundleWithPath:bundles.lastObject];
        [bundles removeLastObject];
        if (bun) {
            // NSLog(@"Loading : %@ into %d", bun.bundleIdentifier, runningApp.processIdentifier);
            [self.injectorProxy injectBundle:bun.executablePath inProcess:runningApp.processIdentifier withReply:^(mach_error_t error) {
                [self queuedInject:runningApp withArray:bundles];
            }];
        } else {
            [self queuedInject:runningApp withArray:bundles];
        }
    }
}

- (void)loadBundle:(NSString*)bundle intoApp:(NSRunningApplication*)app {
    pid_t pid = [app processIdentifier];
        
    // Special check for Dock process
    if ([app.bundleIdentifier isEqualToString:@"com.apple.dock"]) {
        NSBundle *bun = [NSBundle bundleWithPath:@"/Library/Application Support/MacEnhance/CorePlugins/DockKit.bundle"];
        // Don't load anything in the Dock if we can't first load DockKit!
        if (!bun) return;
        
        // Load DockKit
        [self.injectorProxy injectBundle:bun.executablePath inProcess:pid withReply:^(mach_error_t error) { }];
    }
    
    // Check for some cases where we don't load
    BOOL shouldLoad = true;
    
    // ARM cpu and process is translated
    if (self.isARM && app.executableArchitecture == 16777223) shouldLoad = false;
    
    // Process has xcode debugger attached to is
    Boolean isXcodeRunning = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dt.Xcode"].count;
    Boolean isXcodeAttached = false;
    if (isXcodeRunning)
        isXcodeAttached = [self xcodeAttached:pid];
    
    if (isXcodeAttached) shouldLoad = false;
    
    // We made it! Lets inject the loader.
    if (shouldLoad) {
        NSBundle *loader = [NSBundle bundleWithPath:bundle];
        [self.injectorProxy injectBundle:loader.executablePath inProcess:pid withReply:^(mach_error_t error) {
            NSLog(@"Finished injection %@ in %d (%@)", loader.bundleIdentifier, pid, app.bundleIdentifier);
        }];
    }
}

- (void)loadInjectorIntoApp:(NSRunningApplication*)app {
    [self loadBundle:@"/Library/Application Support/MacEnhance/CorePlugins/PluginLoader.bundle" intoApp:app];
}

// Try injecting all valid bundles into all running applications
- (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [self startQueuedInject:app];
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
    
    
    NSArray *paths = @[@"/Library/Application Support/MacEnhance/Plugins"];
    // Plugin watcher
    for (NSString *path in paths /* [MF_PluginManager MacEnhancePluginPaths] */) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path update:^{
            [self injectAllProc];
//            CFDictionaryKeyCallBacks keyCallbacks = {0, NULL, NULL, CFCopyDescription, CFEqual, NULL};
//            CFDictionaryValueCallBacks valueCallbacks  = {0, NULL, NULL, CFCopyDescription, CFEqual};
//            CFMutableDictionaryRef dictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &keyCallbacks, &valueCallbacks);
//            CFDictionaryAddValue(dictionary, CFSTR("LOAD"), CFSTR("1"));
//            CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter(); //CFNotificationCenterGetLocalCenter();
//            CFNotificationCenterPostNotification(center, CFSTR("com.macenhance.MacForgeHelper.update"), NULL, dictionary, TRUE);
//            CFRelease(dictionary);
        }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

// Close and offer to uninstall if main application is trashed while running
+ (void)abortMission {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
    
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
            if (mfAppDelegate) { [mfAppDelegate startQueuedInject:[NSRunningApplication runningApplicationWithProcessIdentifier:pid]]; }
            NSLog(@"CarbonEventHandler Launching nc : %d : %f", pid, [NSDate timeIntervalSinceReferenceDate] * 1000);
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
