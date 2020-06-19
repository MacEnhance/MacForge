//
//  MF_purchasedItem.h
//  MacForge
//
//  Created by Wolfgang Baird on 6/18/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

#import "AppDelegate.h"

#import "MF_Plugin.h"
#import "MF_PluginManager.h"
#import "MF_Purchase.h"
#import "MF_repoData.h"

#import "SYFlatButton.h"
#import <SDWebImage/SDWebImage.h>


@interface MF_purchasedItem : NSViewController {
    MF_Plugin *plug;
}

@property (weak) IBOutlet NSTextField           *bundleName;
@property (weak) IBOutlet NSTextField           *bundleDesc;
@property (weak) IBOutlet NSImageView           *bundleIcon;
@property (weak) IBOutlet NSButton              *bundleBackgroundButton;
@property (weak) IBOutlet SYFlatButton          *bundleGet;
@property (weak) IBOutlet NSProgressIndicator   *bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MF_Plugin*)plugin;

@end
