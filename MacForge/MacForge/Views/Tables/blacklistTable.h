//
//  blacklistTable.h
//  MacForge
//
//  Created by Wolfgang Baird on 7/29/18.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface blacklistTable : NSTableView
@property NSArray *blackList;
@end

@interface blacklistTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property NSString *bundleID;
@end
