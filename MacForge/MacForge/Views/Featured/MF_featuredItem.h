//
//  MF_featuredItem.h
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

#import "MF_Plugin.h"
#import "MF_PluginManager.h"
#import "MF_Purchase.h"
#import "MF_repoData.h"

#import "SLColorArt.h"
#import "SYFlatButton.h"
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredItem : NSCollectionViewItem {
    MF_Plugin *plug;
}

@property IBOutlet NSTextField          *bundleName;
@property IBOutlet NSTextField          *bundleDesc;
@property IBOutlet NSTextField          *bundleDescFull;
@property IBOutlet NSImageView          *bundlePreview;
@property IBOutlet NSImageView          *bundleIcon;
@property IBOutlet SYFlatButton         *bundleGet;
@property IBOutlet NSButton             *bundleBanner;
@property IBOutlet NSProgressIndicator  *bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MF_Plugin*)plugin;

@end

NS_ASSUME_NONNULL_END
