//
//  MF_featuredItem.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;

#import "AppDelegate.h"

#import "MF_Plugin.h"
#import "MF_PluginManager.h"
#import "MF_Purchase.h"
#import "MF_repoData.h"

#import "SYFlatButton.h"
#import <SDWebImage/SDWebImage.h>

@interface MF_featuredItemController : NSViewController {
    MF_Plugin *plug;
}

@property IBOutlet NSTextField          *bundleName;
@property IBOutlet NSTextField          *bundleDesc;
@property IBOutlet NSTextField          *bundleDescFull;
@property IBOutlet NSImageView          *bundlePreview;
@property IBOutlet NSButton             *bundleBanner;
@property IBOutlet NSButton             *bundleButton;
@property IBOutlet SYFlatButton         *bundleGet;
@property IBOutlet NSProgressIndicator  *bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MF_Plugin*)plugin;

@end
