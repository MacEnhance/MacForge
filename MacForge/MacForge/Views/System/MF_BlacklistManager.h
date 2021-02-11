//
//  MF_BlacklistManager.h
//  MacForge
//
//  Created by Wolfgang Baird on 12/25/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MF_BlacklistManager : NSObject

+ (void)removeBlacklistItems:(NSArray*)bundleIDs;
+ (void)addBlacklistItems:(NSArray*)paths;

@end
