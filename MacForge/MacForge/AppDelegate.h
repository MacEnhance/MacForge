//
//  AppDelegate.h
//  MacPlus
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

// Local
@import AppKit;

// External
@import LetsMove;
@import MacForgeKit;
@import Paddle;
@import Sparkle;

#import "PluginManager.h"
#import "FConvenience.h"
#import "SGDirWatchdog.h"
#import "NSBundle+LoginItem.h"
#import "blacklistTable.h"

@interface AppDelegate : NSObject <PaddleDelegate> {
    NSMutableArray *watchdogs;
    PluginManager *_sharedMethods;
}

@property IBOutlet NSWindow *window;
@property IBOutlet NSWindow *srcWin;
@property IBOutlet SUUpdater *updater;

@property (readwrite, nonatomic) Paddle* thePaddle;

// ADs URL
@property (readwrite, nonatomic) NSString* adURL;
@property (readwrite, nonatomic) NSArray* adArray;
@property (readwrite, nonatomic) NSInteger lastAD;

// Tab views
@property IBOutlet NSView *tabMain;
@property IBOutlet NSView *tabAbout;
@property IBOutlet NSView *tabAccount;
@property IBOutlet NSView *tabPlugins;
@property IBOutlet NSView *tabPreferences;
@property IBOutlet NSView *tabSources;
@property IBOutlet NSView *tabDiscover;
@property IBOutlet NSView *tabFeatured;
@property IBOutlet NSView *tabSystemInfo;
@property IBOutlet NSView *tabUpdates;

// Plugins view
@property IBOutlet NSTableView *tblView;
@property IBOutlet NSTableView *sourcesAllTable;
@property IBOutlet NSTableView *sourcesRepoTable;
@property IBOutlet NSTableView *discoverChangesTable;

// Add source
@property IBOutlet NSButton *addsourcesAccept;
@property IBOutlet NSTextField *addsourcesTextFiled;

// Discover view
@property IBOutlet NSView *sourcesRoot;
@property IBOutlet NSView *sourcesBundle;
@property IBOutlet NSScrollView *sourcesURLS;
@property IBOutlet NSScrollView *sourcesPlugins;
@property IBOutlet NSScrollView *discoverChanges;
@property IBOutlet NSButton *sourcesPush;
@property IBOutlet NSButton *sourcesPop;
@property IBOutlet NSButton *sourcestoRoot;
@property IBOutlet NSButton *sourcesAdd;
@property IBOutlet NSButton *sourcesRefresh;
@property IBOutlet NSButton *discoverSelectChanges;
@property IBOutlet NSButton *discoverSelectSources;

// Tab bar items
@property IBOutlet NSButton *viewApps;
@property IBOutlet NSButton *viewPlugins;
@property IBOutlet NSButton *viewPreferences;
@property IBOutlet NSButton *viewSources;
@property IBOutlet NSButton *viewAbout;
@property IBOutlet NSButton *viewDiscover;
@property IBOutlet NSButton *viewChanges;
@property IBOutlet NSButton *viewUpdateCounter;
@property IBOutlet NSButton *viewAccount;
@property IBOutlet NSButton *viewSystem;
@property IBOutlet NSButton *buttonFeedback;
@property IBOutlet NSButton *buttonDonate;
@property IBOutlet NSButton *buttonReport;
@property IBOutlet NSButton *buttonAdvert;
@property IBOutlet NSButton *buttonReddit;
@property IBOutlet NSButton *buttonDiscord;

// About view
@property IBOutlet NSTextField      *appName;
@property IBOutlet NSTextField      *appVersion;
@property IBOutlet NSTextField      *appCopyright;
@property IBOutlet NSButton         *gitButton;
@property IBOutlet NSButton         *sourceButton;
@property IBOutlet NSButton         *emailButton;
@property IBOutlet NSButton         *webButton;
@property IBOutlet NSButton         *xCodeButton;
@property IBOutlet NSButton         *showCredits;
@property IBOutlet NSButton         *showChanges;
@property IBOutlet NSButton         *showEULA;
@property IBOutlet NSTextView       *changeLog;

// Featured view
@property IBOutlet NSView      *featuredContentView;
//@property IBOutlet NSTextField      *appName;
//@property IBOutlet NSTextField      *appVersion;
//@property IBOutlet NSTextField      *appCopyright;
//@property IBOutlet NSButton         *gitButton;
//@property IBOutlet NSButton         *sourceButton;
//@property IBOutlet NSButton         *emailButton;
//@property IBOutlet NSButton         *webButton;
//@property IBOutlet NSButton         *xCodeButton;
//@property IBOutlet NSButton         *showCredits;
//@property IBOutlet NSButton         *showChanges;
//@property IBOutlet NSButton         *showEULA;
//@property IBOutlet NSTextView       *changeLog;

// Preferences view
@property IBOutlet NSButton         *prefDonate;
@property IBOutlet NSButton         *prefAds;
@property IBOutlet NSButton         *prefTips;
@property IBOutlet NSButton         *prefWindow;
@property IBOutlet NSPopUpButton    *prefUpdateAuto;
@property IBOutlet NSPopUpButton    *prefUpdateInterval;
@property IBOutlet NSPopUpButton    *prefStartTab;

// System Information view
@property IBOutlet NSButton         *SIMBLAgentToggle;
@property IBOutlet NSButton         *SIMBLTogggle;
@property IBOutlet NSPopUpButton    *SIMBLLogging;
@property IBOutlet NSButton         *SIPStatus;
@property IBOutlet NSButton         *AMFIStatus;
@property IBOutlet NSScrollView     *blacklistScroll;
@property IBOutlet blacklistTable   *blackListTable;

@property IBOutlet NSButton         *SIPWarning;

- (void)setupEventListener;
- (IBAction)pushView:(id)sender;
- (IBAction)popView:(id)sender;
- (Boolean)keypressed:(NSEvent *)theEvent;
- (IBAction)sourceAddNew:(id)sender;
- (IBAction)sourceAddorRemove:(id)sender;

@end

@interface NSToolTipManager : NSObject {
    double toolTipDelay;
}
+ (id)sharedToolTipManager;
- (void)setInitialToolTipDelay:(double)arg1;
@end
