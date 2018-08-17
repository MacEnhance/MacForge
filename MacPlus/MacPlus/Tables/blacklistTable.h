//
//  blacklistTable.h
//  MacPlus
//
//  Created by Wolfgang Baird on 7/29/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface blacklistTable : NSTableView
@property NSArray *blackList;
@end

@interface blacklistTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property NSString *bundleID;
@end

NS_ASSUME_NONNULL_END
