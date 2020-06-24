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

@import SIPKit;

#import <Collaboration/Collaboration.h>
#import <SDWebImage/SDWebImage.h>
#import "FConvenience.h"
#import "SGDirWatchdog.h"
#import "NSBundle+LoginItem.h"

#import "MF_extra.h"
#import "MF_pluginPreferencesView.h"
#import "MF_accountManager.h"
#import "MF_BlacklistManager.h"
#import "MF_searchView.h"

#import "MF_repoData.h"
#import "MF_PluginManager.h"
#import "blacklistTable.h"

#import "MF_defines.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSearchFieldDelegate, NSWindowDelegate> {
    NSMutableArray *watchdogs;
    MF_PluginManager *_sharedMethods;
    FIRUser *_user;  // Firebase User
}

@property         Boolean               dontKillMe;

// Firebase
//@property (nonatomic, readwrite) FIRFirestore *db;
//@property (strong, nonatomic) FIRDatabaseReference *ref;

// Windows
@property IBOutlet NSWindow             *window;
@property IBOutlet NSWindow             *windowPreferences;

// Sparkle
@property IBOutlet SUUpdater            *updater;

// Preferences
@property IBOutlet NSSegmentedControl   *aboutSelector;
@property IBOutlet NSSegmentedControl   *preferencesTabController;
@property IBOutlet NSView               *preferencesGeneral;
@property IBOutlet NSView               *preferencesAbout;
@property IBOutlet NSView               *preferencesData;
@property IBOutlet NSView               *preferencesBundles;
@property IBOutlet NSSegmentedControl   *preferencesInstallToUser;

// Tab views
@property IBOutlet NSView               *tabMain;
@property IBOutlet NSView               *tabPlugins;
@property IBOutlet NSView               *tabSystemInfo;
@property IBOutlet NSView               *tabUpdates;
@property IBOutlet MF_searchView        *tabSearch;

// Plugins view
@property IBOutlet NSTableView          *tblView;
@property IBOutlet NSView               *viewImages;
@property IBOutlet NSView               *sourcesBundle;

// Extra
@property IBOutlet MF_extra             *sidebarController;

// Top sidebar items
@property IBOutlet NSSearchField        *searchPlugins;
@property IBOutlet MF_sidebarButton     *sidebarFeatured;
@property IBOutlet MF_sidebarButton     *sidebarDiscover;
@property IBOutlet MF_sidebarButton     *sidebarUpdates;
@property IBOutlet NSButton             *viewUpdateCounter;
@property IBOutlet MF_sidebarButton     *sidebarSystem;
@property IBOutlet MF_sidebarButton     *sidebarManage;
@property IBOutlet MF_sidebarButton     *sidebarPluginPrefs;

// Bottom sidebar items
@property IBOutlet MF_sidebarButton     *sidebarWarning;
@property IBOutlet MF_sidebarButton     *sidebarDiscord;
@property IBOutlet MF_sidebarButton     *sidebarAccount;

// About view
@property IBOutlet NSTextField          *appName;
@property IBOutlet NSTextField          *appVersion;
@property IBOutlet NSTextField          *appCopyright;
@property IBOutlet NSButton             *webButton;
@property IBOutlet NSTextView           *changeLog;

// Account view login / register
@property IBOutlet NSButton             *loginLogin;
@property IBOutlet NSButton             *loginLogout;
@property IBOutlet NSTextField          *loginImageURL;
@property IBOutlet NSTextField          *loginUID;
@property IBOutlet NSTextField          *loginEmail;
@property IBOutlet NSTextField          *loginUsername;
@property IBOutlet NSSecureTextField    *loginPassword;

// Account views
@property IBOutlet NSView               *tabAccount;
@property IBOutlet NSView               *tabAccountRegister;
@property IBOutlet NSView               *tabAccountManage;
@property IBOutlet NSView               *tabAccountPurchases;
@property IBOutlet NSButton             *signInOrOutButton;

// Account view profile
@property IBOutlet NSTextField          *email;
@property IBOutlet NSSecureTextField    *password;

// System Information view
@property IBOutlet NSButton             *MacForgePrivHelper;
@property IBOutlet NSButton             *SIP_filesystem;
@property IBOutlet NSButton             *SIP_TaskPID;
@property IBOutlet NSTextField          *SIP_status;
@property IBOutlet NSTextField          *AMFI_status;
@property IBOutlet NSTextField          *LV_status;
@property IBOutlet NSView               *infoDocView;
@property IBOutlet NSScrollView         *infoScroll;
@property IBOutlet blacklistTable       *blackListTable;

- (void)setupEventListener;
- (void)setViewSubView:(NSView*)container :(NSView*)subview;
- (void)updatesearchText;

@end

@interface NSToolTipManager : NSObject {
    double toolTipDelay;
}
+ (id)sharedToolTipManager;
- (void)setInitialToolTipDelay:(double)arg1;
@end
