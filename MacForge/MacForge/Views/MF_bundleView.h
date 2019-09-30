//
//  MF_bundleView.h
//  MacForge
//
//  Created by Wolfgang Baird on 9/29/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;
@import EDStarRating;

#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"
#import "MF_bundlePreviewView.h"

#import "SYFlatButton.h"
#import "ZKSwizzle.h"

@interface MF_bundleView : NSView <EDStarRatingProtocol>

@property IBOutlet EDStarRating*    starRating;
@property IBOutlet NSTextField*     starScore;
@property IBOutlet NSTextField*     starReviews;

// Bundle Display
@property IBOutlet NSTextField*     bundleName;
@property IBOutlet NSTextField*     bundleDesc;
@property IBOutlet NSTextField*     bundleDescShort;
@property IBOutlet NSImageView*     bundleImage;
@property IBOutlet NSImageView*     bundlePreview1;
@property IBOutlet NSImageView*     bundlePreview2;
@property IBOutlet NSButton*        bundlePreviewNext;
@property IBOutlet NSButton*        bundlePreviewPrev;
@property IBOutlet NSButton*        bundleDev;

//@property IBOutlet *        bundlePreviewButton1;
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

// Bundle Buttons
@property IBOutlet SYFlatButton*    bundleInstall;
@property IBOutlet SYFlatButton*    bundleShare;
@property IBOutlet NSButton*        bundleDelete;
@property IBOutlet NSButton*        bundleContact;
@property IBOutlet NSButton*        bundleDonate;

// Bundle Webview
@property IBOutlet WebView*         bundleWebView;

@property NSArray*                  bundlePreviewImages;
@property NSMutableArray*           bundlePreviewImagesMute;
@property NSString*                 currentBundle;
@property NSInteger                 currentPreview;

@end
