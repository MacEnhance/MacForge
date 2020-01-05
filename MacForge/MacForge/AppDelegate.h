//
//  AppDelegate.h
//  MacForge
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

// Local
@import AppKit;

// Pods
@import LetsMove;
@import Sparkle;
@import EDStarRating;

@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@import CocoaMarkdown;

// Firebase
@import FirebaseCore;
//@import FirebaseDatabase;
//@import FirebaseFirestore;
@import FirebaseAuth;
//@import FirebaseStorage;
//@import FirebaseCoreDiagnostics;

// MacForgeKit
@import MacForgeKit;

#import <Collaboration/Collaboration.h>
#import <SDWebImage/SDWebImage.h>
#import "PluginManager.h"
#import "FConvenience.h"
#import "SGDirWatchdog.h"
#import "NSBundle+LoginItem.h"
#import "blacklistTable.h"
#import "MF_BlacklistManager.h"

#import "pluginData.h"

#import "MF_accountManager.h"

@interface AppDelegate : NSObject <NSSearchFieldDelegate> {
    NSMutableArray *watchdogs;
    PluginManager *_sharedMethods;
    FIRUser *_user;  // Firebase User
}

@property IBOutlet NSWindow *window;
@property IBOutlet NSWindow *srcWin;
@property IBOutlet SUUpdater *updater;

// Firebase
//@property (nonatomic, readwrite) FIRFirestore *db;
//@property (strong, nonatomic) FIRDatabaseReference *ref;

// ADs URL
@property (readwrite, nonatomic) NSString* adURL;
@property (readwrite, nonatomic) NSArray* adArray;
@property (readwrite, nonatomic) NSInteger lastAD;

// Tab views
@property IBOutlet NSView *tabMain;
@property IBOutlet NSView *tabAbout;
@property IBOutlet NSView *tabPlugins;
@property IBOutlet NSView *tabPreferences;
@property IBOutlet NSView *tabSources;
@property IBOutlet NSView *tabDiscover;
@property IBOutlet NSView *tabFeatured;
@property IBOutlet NSView *tabSystemInfo;
@property IBOutlet NSView *tabUpdates;

// Account views
@property IBOutlet NSView *tabAccount;
@property IBOutlet NSView *tabAccountRegister;
@property IBOutlet NSView *tabAccountManage;
@property IBOutlet NSView *tabAccountPurchases;
@property IBOutlet NSButton *signInOrOutButton;

// ??
@property IBOutlet NSView *viewImages;

// Plugins view
@property IBOutlet NSTableView *tblView;
@property IBOutlet NSTableView *sourcesAllTable;
@property IBOutlet NSTableView *sourcesRepoTable;
@property IBOutlet NSTableView *discoverChangesTable;

// Add source
@property IBOutlet NSButton *addsourcesAccept;
@property IBOutlet NSTextField *addsourcesTextFiled;

// Discover view
@property IBOutlet NSTableView *changesTable;
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
@property IBOutlet NSSearchField *searchPlugins;
@property IBOutlet NSButton *viewApps;
@property IBOutlet NSButton *viewPlugins;
@property IBOutlet NSButton *viewPreferences;
@property IBOutlet NSButton *viewSources;
@property IBOutlet NSButton *viewAbout;
@property IBOutlet NSButton *viewDiscover;
@property IBOutlet NSButton *viewChanges;
@property IBOutlet NSButton *viewUpdateCounter;
@property IBOutlet NSButton *viewAccount;
@property IBOutlet NSImageView *imgAccount;
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
@property IBOutlet NSButton         *showDev;
@property IBOutlet NSButton         *showChanges;
@property IBOutlet NSButton         *showEULA;
@property IBOutlet NSTextView       *changeLog;

// Account view login / register
@property IBOutlet NSButton             *loginLogin;
@property IBOutlet NSButton             *loginLogout;
@property IBOutlet NSTextField          *loginImageURL;
@property IBOutlet NSTextField          *loginUID;
@property IBOutlet NSTextField          *loginEmail;
@property IBOutlet NSTextField          *loginUsername;
@property IBOutlet NSSecureTextField    *loginPassword;

// Account view profile
//@property IBOutlet NSButton             *login;
//@property IBOutlet NSButton             *logout;
@property IBOutlet NSTextField          *email;
@property IBOutlet NSSecureTextField    *password;

// Featured view
@property IBOutlet NSView      *featuredContentView;

// Preferences view
@property IBOutlet NSButton         *prefDonate;
@property IBOutlet NSButton         *prefAds;
@property IBOutlet NSButton         *prefUpdateBeta;
@property IBOutlet NSButton         *prefTips;
@property IBOutlet NSButton         *prefWindow;
@property IBOutlet NSButton         *prefHideMenubar;
@property IBOutlet NSPopUpButton    *prefUpdateAuto;
@property IBOutlet NSPopUpButton    *prefUpdateInterval;
@property IBOutlet NSPopUpButton    *prefStartTab;
@property IBOutlet NSView           *prefSources;

// System Information view
@property IBOutlet NSButton         *SIMBLAgentToggle;
@property IBOutlet NSButton         *SIMBLTogggle;
@property IBOutlet NSPopUpButton    *SIMBLLogging;

@property IBOutlet NSButton         *AMFIStatus;
@property IBOutlet NSButton         *SIPStatus;

@property IBOutlet NSButton         *SIP_filesystem;
@property IBOutlet NSButton         *SIP_TaskPID;
@property IBOutlet NSButton         *SIP_NVRAM;

@property IBOutlet NSTextField      *SIP_status;
@property IBOutlet NSTextField      *AMFI_status;

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
