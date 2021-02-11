//
//  MF_localPlugin.h
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MF_Plugin.h"
#import "MF_PluginManager.h"
#import "MF_Purchase.h"
#import "MF_repoData.h"

#import "SLColorArt.h"
#import "SYFlatButton.h"
#import <SDWebImage/SDWebImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_localPlugin : NSCollectionViewItem

@property MF_Plugin                     *bundlePlugin;

@property IBOutlet NSTextField          *bundleName;
@property IBOutlet NSTextField          *bundleIdentifier;
@property IBOutlet NSTextField          *bundleVersion;
@property IBOutlet NSImageView          *bundleSupportsARM;
@property IBOutlet NSButton             *bundleEnabled;
@property IBOutlet NSButton             *bundleIcon;

//- (IBAction)getOrOpen:(id)sender;
//- (IBAction)moreInfo:(id)sender;
//- (void)setupWithPlugin:(MF_Plugin*)plugin;

@end

NS_ASSUME_NONNULL_END
