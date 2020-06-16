//
//  MF_bundleView.h
//  MacForge
//
//  Created by Wolfgang Baird on 9/29/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

//@import FirebaseFirestore;

@import AppKit;
@import WebKit;
@import EDStarRating;

#import "AppDelegate.h"
#import "MF_extra.h"
#import "MF_repoData.h"
#import "MF_bundlePreviewView.h"
#import "MF_Purchase.h"
#import "MF_PluginManager.h"

#import "SLColorArt.h"
#import "SYFlatButton.h"

@interface MF_bundleView : NSView <EDStarRatingProtocol>

@property IBOutlet MF_Plugin*       plugin;

@property IBOutlet EDStarRating*    starRating;
@property IBOutlet NSTextField*     starScore;
@property IBOutlet NSTextField*     starReviews;
@property IBOutlet NSButton*        bundleRequiresSIP;
@property IBOutlet NSButton*        bundleRequiresLIB;

@property IBOutlet NSView*          viewHeader;
@property IBOutlet NSView*          viewPreviews;
@property IBOutlet NSView*          viewDescription;
@property IBOutlet NSView*          viewInfo;
@property IBOutlet NSScrollView*    containerView;

// Bundle Display
@property IBOutlet NSTextField*     bundleName;
@property IBOutlet NSTextField*     bundleDesc;
@property IBOutlet NSTextField*     bundleDescShort;
@property IBOutlet NSImageView*     bundleImage;
@property IBOutlet NSButton*        bundlePreviewNext;
@property IBOutlet NSButton*        bundlePreviewPrev;
@property IBOutlet NSButton*        bundleDev;

@property IBOutlet NSImageView*     bundlePreview1;
@property IBOutlet NSImageView*     bundlePreview2;
@property IBOutlet NSButton*        bundlePreviewButton1;
@property IBOutlet NSButton*        bundlePreviewButton2;

// Bundle Infobox
@property IBOutlet NSTextField*     bundleTarget;
@property IBOutlet NSTextField*     bundleDate;
@property IBOutlet NSTextField*     bundleVersion;
@property IBOutlet NSTextField*     bundlePrice;
@property IBOutlet NSTextField*     bundleSize;
@property IBOutlet NSTextField*     bundleID;
@property IBOutlet NSTextField*     bundleCompat;
@property IBOutlet NSTextField*     bundleSeller;
@property IBOutlet NSTextField*     bundleCopyright;

// Bundle Buttons
@property IBOutlet NSProgressIndicator* bundleProgress;
@property IBOutlet SYFlatButton*        bundleInstall;
@property IBOutlet SYFlatButton*        bundleShare;
@property IBOutlet NSButton*            bundleDelete;
@property IBOutlet NSButton*            bundleContact;
@property IBOutlet NSButton*            bundleDonate;

// Bundle Webview
@property IBOutlet WebView*         bundleWebView;

@property NSArray*                  bundlePreviewImages;
@property NSMutableArray*           bundlePreviewImagesMute;
@property NSString*                 currentBundle;
@property NSInteger                 currentPreview;

@end
