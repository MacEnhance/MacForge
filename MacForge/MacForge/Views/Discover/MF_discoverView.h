//
//  MF_discoverView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/22/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_discoverView : NSView <NSTableViewDataSource, NSTableViewDelegate>
@property NSTableView   *tv;
@end
