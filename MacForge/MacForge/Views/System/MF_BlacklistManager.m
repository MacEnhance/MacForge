//
//  MF_BlacklistManager.m
//  MacForge
//
//  Created by Wolfgang Baird on 12/25/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;

#import "MF_BlacklistManager.h"

@implementation MF_BlacklistManager

+ (void)removeBlacklistItems:(NSArray*)bundleIDs {
    NSUserDefaults *sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.macenhance.MacForgeHelper"];
    NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
    for (NSString* bundleID in bundleIDs)
        [newBlacklist removeObject:bundleID];
    [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [sharedPrefs synchronize];
}

+ (void)addBlacklistItems:(NSArray*)paths {
    NSUserDefaults *sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.macenhance.MacForgeHelper"];
    NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
    for (NSURL *url in paths) {
        NSString *path = url.path;
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        NSString *bundleID = [bundle bundleIdentifier];
        if (bundleID.length)
            if (![newBlacklist containsObject:bundleID])
                [newBlacklist addObject:bundleID];
    }
    [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [sharedPrefs synchronize];
}

@end
