//
//  MF_webPlguinTableController.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_featuredView : NSView <NSTableViewDataSource, NSTableViewDelegate>
@property NSTableView *tv;
@end
