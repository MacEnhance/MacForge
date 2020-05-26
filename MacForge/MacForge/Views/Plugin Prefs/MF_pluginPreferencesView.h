//
//  MF_pluginPreferencesView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_pluginPreferencesView : NSView <NSTableViewDataSource, NSTableViewDelegate>

@property NSMetadataQuery       *query;

@property NSArray               *applicationList;
@property NSArray               *pluginList;

@property IBOutlet NSView       *preferencesContainer;
@property IBOutlet NSTableView  *tv;

@end
