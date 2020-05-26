//
//  MF_searchView.h
//  MacForge
//
//  Created by Wolfgang Baird on 5/22/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MF_searchView : NSView <NSTableViewDataSource, NSTableViewDelegate>
@property NSTableView   *tv;
@property NSString      *filter;
@end

