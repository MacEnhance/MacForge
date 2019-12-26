//
//  MF_BlacklistManager.h
//  MacForge
//
//  Created by Wolfgang Baird on 12/25/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_BlacklistManager : NSObject

+ (void)removeBlacklistItems:(NSArray*)bundleIDs;
+ (void)addBlacklistItems:(NSArray*)paths;

@end

NS_ASSUME_NONNULL_END
