//
//  MF_pluginPreferencesView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;
#import "../../../ViewBridge Headers/ViewBridge.h"
#import "../../../PreferenceLoader/PreferenceLoaderProtocol.h"

@interface MF_pluginPreferencesView : NSView <NSTableViewDataSource, NSTableViewDelegate>

@property NSMetadataQuery       *query;

@property NSArray               *applicationList;
@property NSArray               *pluginList;

@property IBOutlet NSView       *preferencesContainer;
@property IBOutlet NSTableView  *tv;

@property (retain) NSXPCConnection *prefLoaderConnection;
@property (retain) id<PreferenceLoaderProtocol> prefLoaderProxy;
@property (retain) NSRemoteView *currentPrefView;
@end
