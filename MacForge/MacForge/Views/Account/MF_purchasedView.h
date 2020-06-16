//
//  MF_purchasedView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/29/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_purchasedView : NSView <NSTableViewDataSource, NSTableViewDelegate>
@property NSTableView   *tv;
@end
