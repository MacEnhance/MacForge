//
//  MF_featuredTab.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredItemController.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredTab : NSView

@property MF_featuredItemController *viewController1;
@property MF_featuredItemController *viewController2;

//// Bundle Display
//@property IBOutlet NSTextField*     bundleName;
//@property IBOutlet NSTextView*      bundleDesc;
//@property IBOutlet NSTextField*     bundleDescShort;
//@property IBOutlet NSImageView*     bundleImage;
//@property IBOutlet NSImageView*     bundlePreview1;
//@property IBOutlet NSButton*        bundlePreviewNext;
//@property IBOutlet NSButton*        bundlePreviewPrev;
//
//// Bundle Infobox
//@property IBOutlet NSTextField*     bundleTarget;
//@property IBOutlet NSTextField*     bundleDate;
//@property IBOutlet NSTextField*     bundleVersion;
//@property IBOutlet NSTextField*     bundlePrice;
//@property IBOutlet NSTextField*     bundleSize;
//@property IBOutlet NSTextField*     bundleID;
//@property IBOutlet NSTextField*     bundleDev;
//@property IBOutlet NSTextField*     bundleCompat;
//
//// Bundle Buttons
//@property IBOutlet NSButton*        bundleInstall;
//@property IBOutlet NSButton*        bundleDelete;
//@property IBOutlet NSButton*        bundleContact;
//@property IBOutlet NSButton*        bundleDonate;
//
//// Bundle Webview
//@property IBOutlet WebView*         bundleWebView;
//
//@property NSArray*                  bundlePreviewImages;
//@property NSString*                 currentBundle;
//@property NSInteger                 currentPreview;

@end

NS_ASSUME_NONNULL_END
