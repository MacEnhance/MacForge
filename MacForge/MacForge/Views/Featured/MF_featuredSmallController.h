//
//  MF_featuredSmallController.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
#import "MSPlugin.h"
#import "PluginManager.h"
#import "MF_Purchase.h"
#import <SDWebImage/SDWebImage.h>
#import "SYFlatButton.h"
#import "AppDelegate.h"
#import "pluginData.h"

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredSmallController : NSViewController {
    MSPlugin *plug;
}

@property (weak) IBOutlet NSTextField           *bundleName;
@property (weak) IBOutlet NSTextField           *bundleDesc;
@property (weak) IBOutlet NSButton              *bundleBanner;
@property (weak) IBOutlet NSButton              *bundleButton;
@property (weak) IBOutlet SYFlatButton          *bundleGet;
@property (weak) IBOutlet NSProgressIndicator   *bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MSPlugin*)plugin;

@end

NS_ASSUME_NONNULL_END
