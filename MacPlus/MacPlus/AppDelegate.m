//
//  AppDelegate.m
//  MacPlus
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

AppDelegate* myDelegate;

NSMutableArray *allLocalPlugins;
NSMutableArray *allReposPlugins;
NSMutableArray *allRepos;

NSMutableDictionary *myPreferences;
NSMutableArray *pluginsArray;

NSMutableDictionary *installedPluginDICT;
NSMutableDictionary *needsUpdate;

NSMutableArray *confirmDelete;

NSArray *sourceItems;
NSArray *discoverItems;
Boolean isdiscoverView = true;

NSDate *appStart;

NSButton *selectedView;

NSMutableDictionary *myDict;
NSUserDefaults *sharedPrefs;
NSDictionary *sharedDict;

@implementation AppDelegate

NSUInteger osx_ver;
NSArray *tabViewButtons;
NSArray *tabViews;

// Shared instance
+ (AppDelegate*) sharedInstance {
    static AppDelegate* myDelegate = nil;
    
    if (myDelegate == nil)
        myDelegate = [[AppDelegate alloc] init];
    
    return myDelegate;
}

// Run bash script
- (NSString*) runCommand: (NSString*)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", command], nil];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

// Show DevMate feedback
- (IBAction)showFeedbackDialog:(id)sender {
    [DevMateKit showFeedbackDialog:nil inMode:DMFeedbackDefaultMode];
}

// Cleanup some stuff when user changes dark mode
- (void)systemDarkModeChange:(NSNotification *)notif {
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        [_changeLog setTextColor:[NSColor whiteColor]];
    } else {
        [_changeLog setTextColor:[NSColor blackColor]];
    }
}

// Startup
- (instancetype)init {
    myDelegate = self;
    appStart = [NSDate date];
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    
    // Make sure default sources are in place
    NSArray *defaultRepos = @[@"https://github.com/w0lfschild/myRepo/raw/master/mytweaks",
                              @"https://github.com/w0lfschild/myRepo/raw/master/urtweaks",
                              @"https://github.com/w0lfschild/macplugins/raw/master"];
    
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    for (NSString *item in defaultRepos)
        if (![[myPreferences objectForKey:@"sources"] containsObject:item])
            [newArray addObject:item];
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
    return self;
}

// Quit when window closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

// Try to install bundles when passed to application
- (void)application:(NSApplication *)sender openFiles:(NSArray*)filenames {
    [PluginManager.sharedInstance installBundles:filenames];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DevMateKit sendTrackingReport:nil delegate:nil];
    [DevMateKit setupIssuesController:nil reportingUnhandledIssues:YES];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.w0lf.MacPlusNotify"
                                                                 object:nil
                                                                  queue:nil
                                                             usingBlock:^(NSNotification *notification)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([notification.object isEqualToString:@"prefs"]) [self selectView:self->_viewPreferences];
            if ([notification.object isEqualToString:@"about"]) [self selectView:self->_viewAbout];
            if ([notification.object isEqualToString:@"manage"]) [self selectView:self->_viewPlugins];
            if ([notification.object isEqualToString:@"check"]) { [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter]; }
        });
    }];

    // Loop looking for bundle updates
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter];
    });

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if (args.count > 1) {
        if ([args containsObject:@"prefs"]) [self selectView:_viewPreferences];
        if ([args containsObject:@"about"]) [self selectView:_viewAbout];
        if ([args containsObject:@"manage"]) [self selectView:_viewPlugins];
    }

//    [self installXcodeTemplate];
    
//    DMKitDebugAddDevMateMenu();
    
//    Paddle *thePaddle = [Paddle sharedInstance];
//    [thePaddle setProductId:@"534403"];
//    [thePaddle setVendorId:@"26643"];
//    [thePaddle setApiKey:@"02a3c57238af53b3c465ef895729c765"];
//
//
//    [PaddleAnalyticsKit enableTracking];
//
//    NSDictionary *productInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 @"1.99", kPADCurrentPrice,
//                                 @"Wolfgang Baird", kPADDevName,
//                                 @"USD", kPADCurrency,
//                                 @"https://dl.devmate.com/org.w0lf.cDock-GUI/icons/5aae1388a46dd_128.png", kPADImage,
//                                 @"moreMenu", kPADProductName,
//                                 @"0", kPADTrialDuration,
//                                 @"Thanks for purchasing", kPADTrialText,
//                                 @"icon.icns", kPADProductImage,
//                                 nil];
//
//    [thePaddle startLicensing:productInfo timeTrial:YES withWindow:self.window];
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL verified, NSError *error) {
//        if (verified) {
//            NSLog(@"Verified");
//        } else {
//            NSLog(@"Not verified: %@", [error localizedDescription]);
//        }
//    }];
//
//
//    PaddleStoreKit *psk = [PaddleStoreKit sharedInstance];
//    [psk setDelegate:psk.delegate];
//    [psk showProduct:@"534403-1"];
    
//    [thePaddle startPurchaseForChildProduct:@"534403-1"];
//
//    [[PADProduct alloc] productInfo:@"534403.1" apiKey:@"02a3c57238af53b3c465ef895729c765" vendorId:@"26643" withCompletionBlock:^(BOOL fin) { NSLog(@"Hi"); }];
    
//    [[PaddleStoreKit sharedInstance] showProduct:@"534403.1"];
//    [[PaddleStoreKit sharedInstance] showStoreView];
//    [[PaddleStoreKit sharedInstance] showStoreViewForProductIds:@[@"534403.1", @"534403.2"]];
    
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL ver, NSError *e){ NSLog(@"%hhd : %@", ver, e.localizedDescription); }];
//    [thePaddle startLicensing:productInfo timeTrial:NO withWindow:self.window];
//    [thePaddle startLicensingSilently:productInfo timeTrial:NO];
//    [thePaddle setupChildProduct:@"534403.1" productInfo:productInfo timeTrial:NO];
//    [thePaddle startPurchaseForChildProduct:@"534403.1"];
//    [thePaddle verifyLicenceForChildProduct:@"534403-1" withCompletionBlock:^(BOOL ver, NSError *e){ NSLog(@"%hhd : %@", ver, e.localizedDescription); }];
    
//    [thePaddle startLicensingSilently:productInfo timeTrial:NO];
//    [thePaddle setupChildProduct:@"534403.1" productInfo:productInfo timeTrial:NO];
//    [thePaddle startPurchaseForChildProduct:@"534403.1"];
//    [thePaddle purchaseChildProduct:@"534403.1" withWindow:self.window completionBlock:^(NSString* response, NSString* email, BOOL completed, NSError *error, NSDictionary *checkoutData){
//
//    }];
    
    
//    - (void)purchaseChildProduct:(nonnull NSString *)childProductId withWindow:(nullable NSWindow *)window completionBlock:(nonnull void (^)(NSString * _Nullable response, NSString * _Nullable email, BOOL completed, NSError * _Nullable error, NSDictionary * _Nullable checkoutData))completionBlock;

    
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL verified, NSError *error) {
//        if (verified) {
//            NSLog(@"Verified");
//        } else {
//            NSLog(@"Not verified: %@", [error localizedDescription]);
//        }
//    }];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:appStart];
    NSLog(@"Launch time : %f Seconds", executionTime);
}

- (void)executionTime:(NSString*)s {
    SEL sl = NSSelectorFromString(s);
    NSDate *startTime = [NSDate date];

    if ([self respondsToSelector:sl])
        [self performSelector:sl];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
    NSLog(@"%@ execution time : %f Seconds", s, executionTime);
}

// Loading
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    sourceItems = [NSArray arrayWithObjects:_sourcesURLS, _sourcesPlugins, _sourcesBundle, nil];
    discoverItems = [NSArray arrayWithObjects:_discoverChanges, _sourcesBundle, nil];

    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    myPreferences = [self getmyPrefs];

    [_sourcesRoot setSubviews:[[NSArray alloc] initWithObjects:_discoverChanges, nil]];
    
    [self executionTime:@"updateAdButton"];
    [self executionTime:@"tabs_sideBar"];
    [self executionTime:@"setupWindow"];
    [self executionTime:@"setupPrefstab"];
    [self executionTime:@"addLoginItem"];
    [self executionTime:@"launchHelper"];
//    [self updateAdButton];
//    [self tabs_sideBar];
//    [self setupWindow];
//    [self setupPrefstab];
//    [self addLoginItem];
//    [self launchHelper];
    
    // Setup plugin table
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [self setupEventListener];
    [_window makeKeyAndOrderFront:self];
    
    [self executionTime:@"setupSIMBLview"];
//    [self setupSIMBLview];

    [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(keepThoseAdsFresh) userInfo:nil repeats:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    
    // Make sure we're in /Applications
    PFMoveToApplicationsFolderIfNecessary();
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


// Setup sidebar
- (void)tabs_sideBar {
    NSInteger height = _viewPlugins.frame.size.height;
    
    tabViewButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSystem, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSArray *topButtons = [NSArray arrayWithObjects:_viewDiscover, _viewPlugins, _viewSources, _viewChanges, _viewSystem, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSUInteger yLoc = _window.frame.size.height - 44 - height;
    for (NSButton *btn in topButtons) {
        NSRect newFrame = [btn frame];
        newFrame.origin.x = 0;
        newFrame.origin.y = yLoc;
        yLoc -= (height - 1);
        [btn setFrame:newFrame];
        [btn setWantsLayer:YES];
        [btn setTarget:self];
    }
    
    [_viewUpdateCounter setFrameOrigin:CGPointMake(_viewChanges.frame.origin.x + _viewChanges.frame.size.width * .6,
                                                   _viewChanges.frame.origin.y + _viewChanges.frame.size.height * .5 - _viewUpdateCounter.frame.size.height * .5)];
    
    for (NSButton *btn in tabViewButtons)
        [btn setAction:@selector(selectView:)];
    
    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonDonate, _buttonAdvert, _buttonFeedback, _buttonReport, nil];
    NSMutableArray *visibleButons = [[NSMutableArray alloc] init];
    for (NSButton *btn in bottomButtons)
        if (![btn isHidden])
            [visibleButons addObject:btn];
    bottomButtons = [visibleButons copy];
    
    yLoc = ([bottomButtons count] - 1) * (height - 1);
    for (NSButton *btn in bottomButtons) {
        NSRect newFrame = [btn frame];
        newFrame.origin.x = 0;
        newFrame.origin.y = yLoc;
        yLoc -= (height - 1);
        [btn setFrame:newFrame];
        [btn setAutoresizingMask:NSViewMaxYMargin];
        [btn setWantsLayer:YES];
    }
}


- (void)setupWindow {
    [_window setTitle:@""];
    [_window setMovableByWindowBackground:YES];
    
    if (osx_ver > 9) {
        [_window setTitlebarAppearsTransparent:true];
        _window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    }
    
    [self simbl_blacklist];
    [self getBlacklistAPPList];
    
    // Add blurred background if NSVisualEffectView exists
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_window setBackgroundColor:[NSColor whiteColor]];
    }
    
    [_window.contentView setWantsLayer:YES];
    
    NSBox *vert = [[NSBox alloc] initWithFrame:CGRectMake(_viewPlugins.frame.size.width - 1, 0, 1, _window.frame.size.height)];
    [vert setBoxType:NSBoxSeparator];
    [vert setAutoresizingMask:NSViewHeightSizable];
    [_window.contentView addSubview:vert];
    
//
//    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonFeedback, _buttonDonate, _buttonReport, nil];
//
//    for (NSButton *btn in bottomButtons) {
//        [btn setWantsLayer:YES];
//        [btn.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
//    }
    
    tabViews = [NSArray arrayWithObjects:_tabPlugins, _tabSources, _tabUpdates, _tabSystemInfo, _tabSources, _tabAbout, _tabPreferences, nil];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [_appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    [_appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                                 [infoDict objectForKey:@"CFBundleShortVersionString"],
                                 [infoDict objectForKey:@"CFBundleVersion"]]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString * currentYEAR = [formatter stringFromDate:[NSDate date]];
    [_appCopyright setStringValue:[NSString stringWithFormat:@"Copyright © 2015 - %@ Wolfgang Baird", currentYEAR]];
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"Changelog" withExtension:@"rtf"] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        [_changeLog setTextColor:[NSColor whiteColor]];
    } else {
        [_changeLog setTextColor:[NSColor blackColor]];
    }
    
    // Select tab view
    if ([[myPreferences valueForKey:@"prefStartTab"] integerValue] >= 0) {
        NSInteger tab = [[myPreferences valueForKey:@"prefStartTab"] integerValue];
        [self selectView:[tabViewButtons objectAtIndex:tab]];
        [_prefStartTab selectItemAtIndex:tab];
    } else {
        [self selectView:_viewPlugins];
        [_prefStartTab selectItemAtIndex:0];
    }
}

- (void)addLoginItem {
    NSBundle *helperBUNDLE = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacPlusHelper"]];
    [helperBUNDLE enableLoginItem];
}

- (void)launchHelper {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Path to MacPlusHelper
        NSString *path = [NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacPlusHelper.app", [[NSBundle mainBundle] bundlePath]];
        
        // Launch helper if it's not open
        //    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacPlusHelper"].count == 0)
        //        [[NSWorkspace sharedWorkspace] launchApplication:path];
        
        // Always relaunch in developement
        for (NSRunningApplication *run in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacPlusHelper"])
            [run terminate];
        [Workspace launchApplication:path];
    });
}

- (void)setupPrefstab {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSUInteger logLevel = [[[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"SIMBLLogLevel"] integerValue];
    [_SIMBLLogging selectItemAtIndex:logLevel];
    [_prefDonate setState:[[myPreferences objectForKey:@"prefDonate"] boolValue]];
    [_prefTips setState:[[myPreferences objectForKey:@"prefTips"] boolValue]];
    [_prefWindow setState:[[myPreferences objectForKey:@"prefWindow"] boolValue]];
    
    if ([[myPreferences objectForKey:@"prefWindow"] boolValue])
        [_window setFrameAutosaveName:@"MainWindow"];
    
    if ([[myPreferences objectForKey:@"prefTips"] boolValue]) {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUAutomaticallyUpdate"]) {
        [_prefUpdateAuto selectItemAtIndex:2];
        [_updater checkForUpdatesInBackground];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"]) {
        [_prefUpdateAuto selectItemAtIndex:1];
        [_updater checkForUpdatesInBackground];
    } else {
        [_prefUpdateAuto selectItemAtIndex:0];
    }
    
    [_prefUpdateInterval selectItemWithTag:[[myPreferences objectForKey:@"SUScheduledCheckInterval"] integerValue]];
    
    [[_gitButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_sourceButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_webButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [[_emailButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [_sourceButton setAction:@selector(visitSource)];
    [_gitButton setAction:@selector(visitGithub)];
    [_webButton setAction:@selector(visitWebsite)];
    [_emailButton setAction:@selector(sendEmail)];
}

- (void)installXcodeTemplate {
    if ([Workspace absolutePathForAppBundleWithIdentifier:@"com.apple.dt.Xcode"].length > 0) {
        NSString *localPath = [NSBundle.mainBundle pathForResource:@"plugin_template" ofType:@"zip"];
        NSString *installPath = [FileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject.path;
        installPath = [NSString stringWithFormat:@"%@/Developer/Xcode/Templates/Project Templates/MacPlus", installPath];
        NSString *installFile = [NSString stringWithFormat:@"%@/MacPlus plugin.xctemplate", installPath];
        if (![FileManager fileExistsAtPath:installFile]) {
            // Make intermediaries
            NSError *err;
            [FileManager createDirectoryAtPath:installPath withIntermediateDirectories:true attributes:nil error:&err];
            NSLog(@"%@", err);
            
            // unzip our plugin demo project
            NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", localPath, @"-d", installPath]];
            [task waitUntilExit];
            if ([task terminationStatus] == 0) {
                // Yay
            }
        }
    }
}

- (IBAction)startCoding:(id)sender {
    // Open a test plugin for the user
    NSString *localPath = [NSBundle.mainBundle pathForResource:@"plugin_template" ofType:@"zip"];
    NSString *installPath = [NSURL fileURLWithPath:[NSHomeDirectory()stringByAppendingPathComponent:@"Desktop"]].path;
    installPath = [NSString stringWithFormat:@"%@/MacPlus_plugin_demo", installPath];
    NSString *installFile = [NSString stringWithFormat:@"%@/test.xcodeproj", installPath];
    if ([FileManager fileExistsAtPath:installFile]) {
        // Open the project if it exists
        [Workspace openFile:installFile];
    } else {
        // unzip our plugin demo project
        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", localPath, @"-d", installPath]];
        [task waitUntilExit];
        if ([task terminationStatus] == 0) {
            // presumably the only case where we've successfully installed
            [Workspace openFile:installFile];
        }
    }
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://goo.gl/DSyEFR"]];
}

- (IBAction)report:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/mySIMBL/issues/new"]];
}

- (void)sendEmail {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:aguywithlonghair@gmail.com"]];
}

- (void)visitGithub {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild"]];
}

- (void)visitSource {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/mySIMBL"]];
}

- (void)visitWebsite {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://w0lfschild.github.io/app_mySIMBL.html"]];
}

- (void)setupEventListener {
    watchdogs = [[NSMutableArray alloc] init];
    for (NSString *path in [PluginManager SIMBLPaths]) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path
                                                               update:^{
                                                                   [PluginManager.sharedInstance readPlugins:self->_tblView];
                                                               }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

- (IBAction)changeAutoUpdates:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender indexOfSelectedItem];
    if (selected == 0)
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUEnableAutomaticChecks"];
    if (selected == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUAutomaticallyUpdate"];
    }
    if (selected == 2) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUAutomaticallyUpdate"];
    }
}

- (IBAction)changeUpdateFrequency:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender selectedTag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:selected] forKey:@"SUScheduledCheckInterval"];
}

- (IBAction)changeSIMBLLogging:(id)sender {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:plist] mutableCopy];
    NSString *logLevel = [NSString stringWithFormat:@"%ld", [_SIMBLLogging indexOfSelectedItem]];
    [dict setObject:logLevel forKey:@"SIMBLLogLevel"];
    [dict writeToFile:plist atomically:YES];
}

- (IBAction)toggleTips:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
    if ([btn state])
        [test setInitialToolTipDelay:0.1];
    else
        [test setInitialToolTipDelay:2];
}

- (IBAction)toggleSaveWindow:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    if ([btn state]) {
        [[_window windowController] setShouldCascadeWindows:NO];      // Tell the controller to not cascade its windows.
        [_window setFrameAutosaveName:[_window representedFilename]];
    } else {
        [_window setFrameAutosaveName:@""];
    }
}

- (IBAction)toggleDonateButton:(id)sender {
    NSButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefDonate"];
    if ([btn state]) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:0];
        [[_buttonDonate animator] setHidden:true];
        [NSAnimationContext endGrouping];
    } else {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:1];
        [[_buttonDonate animator] setHidden:false];
        [NSAnimationContext endGrouping];
    }
}

- (IBAction)inject:(id)sender {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [SIMBLFramework SIMBL_injectAll];
//        [[NSSound soundNamed:@"Blow"] play];
//    });
}

- (IBAction)showAbout:(id)sender {
    [self selectView:_viewAbout];
}

- (IBAction)showPrefs:(id)sender {
    [self selectView:_viewPreferences];
}

- (IBAction)aboutInfo:(id)sender {
    if ([sender isEqualTo:_showChanges]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignLeft:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
        
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    if ([sender isEqualTo:_showCredits]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignCenter:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
    }
    if ([sender isEqualTo:_showEULA]) {
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] init];
        for (NSString *item in [FileManager contentsOfDirectoryAtPath:NSBundle.mainBundle.resourcePath error:nil]) {
            if ([item containsString:@"LICENSE"]) {
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:item withExtension:@""] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n---------- ---------- ---------- ---------- ----------\n\n"]];
            }
        }
        [_changeLog.textStorage setAttributedString:mutableAttString];
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        [_changeLog setTextColor:[NSColor whiteColor]];
    } else {
        [_changeLog setTextColor:[NSColor blackColor]];
    }
}

- (IBAction)toggleStartTab:(id)sender {
    NSPopUpButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[btn indexOfSelectedItem]] forKey:@"prefStartTab"];
}

- (IBAction)segmentDiscoverTogglePush:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    NSArray *segements = @[_sourcesURLS, _discoverChanges];
    NSView* view = segements[clickedSegment];
    [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [view setFrameSize:_sourcesRoot.frame.size];
    isdiscoverView = clickedSegment;
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:view];
//    [_sourcesRoot.layer setBackgroundColor:NSColor.greenColor.CGColor];
}

- (IBAction)segmentNavPush:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    if (clickedSegment == 0) {
        [self popView:nil];
    } else {
        [self pushView:nil];
    }
}

- (void)reloadTable:(NSView *)view {
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE
    
    for (NSView *subview in subviews) {
        // Do what you want to do with the subview
        if ([subview.className isEqualToString:@"repopluginTable"]) {
            [subview performSelector:@selector(reloadData)];
            break;
        } else {
            // List the subviews of subview
            [self reloadTable:subview];
        }
    }
}

- (IBAction)pushView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    if ([_sourcesAllTable selectedRow] > -1) {
        [_sourcesPop setEnabled:true];

        if ((cur + 1) < [currView count]) {
            NSView *newView = [currView objectAtIndex:cur + 1];
            [newView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [newView setFrameSize:_sourcesRoot.frame.size];
//            [[_sourcesRoot animator] setSubviews:@[newView]];
            [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[currView objectAtIndex:cur + 1]];
            [_window makeFirstResponder: [currView objectAtIndex:cur + 1]];
        }
        
        if ((cur + 2) >= [currView count]) {
            [_sourcesPush setEnabled:false];
        } else {
            [_sourcesPush setEnabled:true];
            [self reloadTable:_sourcesRoot];
//            dumpViews(_sourcesRoot, 0);
//            if (osx_ver > 9) {
//                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] firstObject] reloadData];
//            } else {
//                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] lastObject] reloadData];
//            }
        }
        
        [_sourcesRoot setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
}

- (IBAction)popView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    [_sourcesPush setEnabled:true];
    if ((cur - 1) <= 0)
        [_sourcesPop setEnabled:false];
    else
        [_sourcesPop setEnabled:true];
    if ((cur - 1) >= 0) {
        NSView *incoming = [currView objectAtIndex:cur - 1];
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:incoming];
        [_window makeFirstResponder:incoming];
    }
}

- (IBAction)rootView:(id)sender {
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    NSView *currView = _sourcesURLS;
    if (isdiscoverView) currView = _discoverChanges;
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:currView];
}

- (IBAction)selectView:(id)sender {
    selectedView = sender;
    if ([tabViewButtons containsObject:sender]) {
        NSView *v = [tabViews objectAtIndex:[tabViewButtons indexOfObject:sender]];
//        [v.layer setBackgroundColor:[NSColor redColor].CGColor];
        [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [v setFrame:_tabMain.frame];
        [v setFrameOrigin:NSMakePoint(0, 0)];
        [v setTranslatesAutoresizingMaskIntoConstraints:true];
        [_tabMain setSubviews:[NSArray arrayWithObject:v]];
        [_tabMain setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
    for (NSButton *g in tabViewButtons) {
        if (![g isEqualTo:sender])
            [[g layer] setBackgroundColor:[NSColor clearColor].CGColor];
        else
//            [[g layer] setBackgroundColor:[NSColor colorWithCalibratedRed:0.88f green:0.88f blue:0.88f alpha:0.258f].CGColor];
            [[g layer] setBackgroundColor:[NSColor colorWithCalibratedRed:0.121f green:0.4375f blue:0.1992f alpha:0.2578f].CGColor];
    }
}

- (IBAction)sourceAddorRemove:(id)sender {
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    NSString *input = _addsourcesTextFiled.stringValue;
    NSArray *arr = [input componentsSeparatedByString:@"\n"];
    for (NSString* item in arr) {
        if ([item length]) {
            if ([newArray containsObject:item]) {
                [newArray removeObject:item];
            } else {
                [newArray addObject:item];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
    [_srcWin close];
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)refreshSources:(id)sender {
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)sourceAddNew:(id)sender {
    NSRect newFrame = _window.frame;
    newFrame.origin.x += (_window.frame.size.width / 2) - (_srcWin.frame.size.width / 2);
    newFrame.origin.y += (_window.frame.size.height / 2) - (_srcWin.frame.size.height / 2);
    newFrame.size.width = _srcWin.frame.size.width;
    newFrame.size.height = _srcWin.frame.size.height;
    [_srcWin setFrame:newFrame display:true];
    [_window addChildWindow:_srcWin ordered:NSWindowAbove];
    [_srcWin makeKeyAndOrderFront:self];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMinimumPosition < 125) {
        proposedMinimumPosition = 125;
    }
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMaximumPosition >= 124) {
        proposedMaximumPosition = 125;
    }
    return proposedMaximumPosition;
}

- (IBAction)toggleAMFI:(id)sender {
    [MacPlusKit AMFI_toggle];
    [_AMFIStatus setState:[MacPlusKit AMFI_enabled]];
}

- (void)setupSIMBLview {
    [_SIMBLTogggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacPlus.Injector"]];
    [_SIMBLAgentToggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacPlus.Installer"]];
//    [_SIPStatus setState:[MacPlusKit SIP_enabled]];
//    [_AMFIStatus setState:[MacPlusKit AMFI_enabled]];
}

- (void)simbl_blacklist {
    NSString *plist = @"Library/Preferences/org.w0lf.SIMBLAgent.plist";
    NSMutableDictionary *SIMBLPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:plist]];
    NSArray *blacklist = [SIMBLPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI"];
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:blacklist];
    for (NSString *app in alwaysBlaklisted)
        if (![blacklist containsObject:app])
            [newlist addObject:app];
    [SIMBLPrefs setObject:newlist forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [SIMBLPrefs writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:plist] atomically:YES];
}

- (void)getBlacklistAPPList {
//    myDict = [[NSMutableDictionary alloc] init];
//
//    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
//        NSString *repin = [self runCommand:@"/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep path: | grep .app | sed -e 's/path://g' -e 's/^[ \t]*//' | sort | uniq"];
//        NSArray *ary = [repin componentsSeparatedByString:@"\n"];
//
//        for (NSString *appPath in ary) {
//            if ([[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
//                NSString *appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
//                NSString *appBundle = [[NSBundle bundleWithPath:appPath] bundleIdentifier];
//                NSArray *jumboTron = [NSArray arrayWithObjects:appName, appPath, appBundle, nil];
//                [myDict setObject:jumboTron forKey:appName];
//            }
//        }
//
//        NSArray *keys = [myDict allKeys];
//        NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//        sortedKeys = [[sortedKeys reverseObjectEnumerator] allObjects];
//
//        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.SIMBLAgent"];
//        sharedDict = [sharedPrefs dictionaryRepresentation];
//
//        NSArray *blacklisted = [sharedDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
//
//        dispatch_async(dispatch_get_main_queue(), ^(void){
//            CGRect frame = self->_blacklistScroll.frame;
//            frame.size.height = 0;
//            int count = 0;
//            for (NSString *app in sortedKeys) {
//                NSArray *myApp = [myDict valueForKey:app];
//                if ([myApp count] == 3) {
//                    CGRect buttonFrame = CGRectMake(10, (25 * count), 150, 22);
//                    NSButton *newButton = [[NSButton alloc] initWithFrame:buttonFrame];
//                    [newButton setButtonType:NSButtonTypeSwitch];
//                    [newButton setTitle:[myApp objectAtIndex:0]];
//                    [newButton sizeToFit];
//                    [newButton setAction:@selector(toggleBlacklistItem:)];
//                    //            [sharedDict valueForKey:[myApp objectAtIndex:2]] == [NSNumber numberWithUnsignedInteger:0]
//                    if ([blacklisted containsObject:[myApp objectAtIndex:2]]) {
//                        //                NSLog(@"\n\nApplication: %@\nBundle ID: %@\n\n", app, bundleString);
//                        [newButton setState:NSControlStateValueOn];
//                    } else {
//                        [newButton setState:NSControlStateValueOff];
//                    }
//                    [self->_blacklistScroll.documentView addSubview:newButton];
//                    count += 1;
//                    frame.size.height += 25;
//                }
//            }
//
//            frame.size.width = 272;
//            [self->_blacklistScroll.documentView setFrame:frame];
//            [self->_blacklistScroll.contentView scrollToPoint:NSMakePoint(0, ((NSView*)self->_blacklistScroll.documentView).frame.size.height - self->_blacklistScroll.contentSize.height)];
//            [self->_blacklistScroll setHasHorizontalScroller:NO];
//        });
//    });
}

- (IBAction)toggleBlacklistItem:(NSButton*)btn {
    if ([sharedPrefs isEqual:nil]) {
        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"org.w0lf.SIMBLAgent"];
        sharedDict = [sharedPrefs dictionaryRepresentation];
    }
    NSString *bundleString = [[myDict objectForKey:btn.title] objectAtIndex:2];
    NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
    if (btn.state == NSOnState) {
        NSLog(@"Adding key: %@", bundleString);
        [newBlacklist addObject:bundleString];
        [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    } else {
        NSLog(@"Deleting key: %@", bundleString);
        [newBlacklist removeObject:bundleString];
        [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    }
    [sharedPrefs synchronize];
}

- (IBAction)uninstallMacPlus:(id)sender {
    [MacPlusKit MacPlus_remove];
}

- (IBAction)visit_ad:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_adURL]];
}

- (void)keepThoseAdsFresh {
    if (_adArray != nil) {
        if (!_buttonAdvert.hidden) {
            NSInteger arraySize = _adArray.count;
            NSInteger displayNum = (NSInteger)arc4random_uniform((int)[_adArray count]);
            if (displayNum == _lastAD) {
                displayNum++;
                if (displayNum >= arraySize)
                    displayNum -= 2;
                if (displayNum < 0)
                    displayNum = 0;
            }
            _lastAD = displayNum;
            NSDictionary *dic = [_adArray objectAtIndex:displayNum];
            NSString *name = [dic objectForKey:@"name"];
            name = [NSString stringWithFormat:@"    %@", name];
            NSString *url = [dic objectForKey:@"homepage"];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:1.25];
                [[self->_buttonAdvert animator] setTitle:name];
            } completionHandler:^{
            }];
            if (url)
                _adURL = url;
            else
                _adURL = @"https://github.com/w0lfschild/mySIMBL";
        }
    }
}

- (void)updateAdButton {
    // Local ads
    NSArray *dict = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ads" ofType:@"plist"]];
    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
    NSDictionary *dic = [dict objectAtIndex:displayNum];
    NSString *name = [dic objectForKey:@"name"];
    name = [NSString stringWithFormat:@"    %@", name];
    NSString *url = [dic objectForKey:@"homepage"];
    
    [_buttonAdvert setTitle:name];
    if (url)
        _adURL = url;
    else
        _adURL = @"https://github.com/w0lfschild/mySIMBL";
    
    _adArray = dict;
    _lastAD = displayNum;
    
    // Check web for new ads
    dispatch_queue_t queue = dispatch_queue_create("com.yourdomain.yourappname", NULL);
    dispatch_async(queue, ^{
        //code to be executed in the background
        
        NSURL *installURL = [NSURL URLWithString:@"https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/ads.plist"];
        NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
        NSError *error;
        NSURLResponse *response;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (!result) {
            // Download failed
            // NSLog(@"mySIMBL : Error");
        } else {
            NSPropertyListFormat format;
            NSError *err;
            NSArray *dict = (NSArray*)[NSPropertyListSerialization propertyListWithData:result
                                                                                options:NSPropertyListMutableContainersAndLeaves
                                                                                 format:&format
                                                                                  error:&err];
            // NSLog(@"mySIMBL : %@", dict);
            if (dict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //code to be executed on the main thread when background task is finished
                    
                    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
                    NSDictionary *dic = [dict objectAtIndex:displayNum];
                    NSString *name = [dic objectForKey:@"name"];
                    name = [NSString stringWithFormat:@"    %@", name];
                    NSString *url = [dic objectForKey:@"homepage"];
                    
                    [self->_buttonAdvert setTitle:name];
                    if (url)
                        self->_adURL = url;
                    else
                        self->_adURL = @"https://github.com/w0lfschild/mySIMBL";
                    
                    self->_adArray = dict;
                    self->_lastAD = displayNum;
                });
            }
        }
    });
}

- (Boolean)keypressed:(NSEvent *)theEvent {
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    bool                specKey     =   false;
    
    switch (code) {
        case NSLeftArrowFunctionKey: {
            [self popView:nil];
            specKey = true;
            break;
        }
        case NSRightArrowFunctionKey: {
            [self pushView:nil];
            specKey = true;
            break;
        }
        case NSCarriageReturnCharacter: {
            [self pushView:nil];
            specKey = true;
            break;
        }
    }
    
    return specKey;
}

@end
