//
//  NSBundle+LoginItem.h
//
//  Created by Tom Li on 11/10/14.
//  Copyright (c) 2014 Inspirify Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (LoginItem)

- (void)enableLoginItem;

- (void)disableLoginItem;

- (BOOL)isLoginItemEnabled;


@end
