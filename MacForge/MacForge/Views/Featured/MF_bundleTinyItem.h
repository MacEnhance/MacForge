//
//  MF_bundleTinyItem.h
//  MacForge
//
//  Created by Wolfgang Baird on 2/8/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;
#import "MSPlugin.h"
#import "PluginManager.h"
#import "MF_Purchase.h"
#import <SDWebImage/SDWebImage.h>
#import "SYFlatButton.h"
#import "AppDelegate.h"
#import "pluginData.h"

@interface MF_bundleTinyItem : NSViewController
{
    MSPlugin *plug;
}

@property (weak) IBOutlet NSTextField           *bundleName;
@property (weak) IBOutlet NSTextField           *bundleDesc;
@property (weak) IBOutlet NSImageView           *bundleBanner;
@property (weak) IBOutlet NSButton              *bundleBackgroundButton;
@property (weak) IBOutlet NSButton              *bundleButton;
@property (weak) IBOutlet SYFlatButton          *bundleGet;
@property (weak) IBOutlet NSProgressIndicator   *bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MSPlugin*)plugin;

@end
