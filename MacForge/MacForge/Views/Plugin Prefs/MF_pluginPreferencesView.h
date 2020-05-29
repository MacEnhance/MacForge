//
//  MF_pluginPreferencesView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;
#import "MF_extra.h"
#import "MF_PluginManager.h"
#import "SGDirWatchdog.h"
#import "ViewBridge.h"
#import "PreferenceLoaderProtocol.h"

@interface MF_pluginPreferencesView : NSView <NSTableViewDataSource, NSTableViewDelegate>

@property NSArray                   *pluginList;
@property IBOutlet SGDirWatchdog    *watchDog;
@property IBOutlet NSView           *preferencesContainer;
@property IBOutlet NSTableView      *tv;
@property IBOutlet NSSegmentedControl      *seg;

@property (retain) NSXPCConnection *prefLoaderConnection;
@property (retain) id<PreferenceLoaderProtocol> prefLoaderProxy;
@property (retain) NSRemoteView *currentPrefView;
@end
