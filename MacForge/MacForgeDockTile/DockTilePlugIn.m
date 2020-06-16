//
//  DockTilePlugIn.m
//  MacForgeDockTile
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#import "DockTilePlugIn.h"

@implementation DockTilePlugIn

static void updateCount(NSDockTile *tile) {
    CFPreferencesAppSynchronize(CFSTR("com.macenhance.MacForge"));
    NSInteger updateCounter = CFPreferencesGetAppIntegerValue(CFSTR("updateCount"), CFSTR("com.macenhance.MacForge"), NULL);
    if (updateCounter != 0)
        [tile setBadgeLabel:[NSString stringWithFormat:@"%ld", (long)updateCounter]];
    else {
        [tile setBadgeLabel:@""];
    }
}

//- (NSMenu*)dockMenu {
//    NSMenu *recentGamesMenu = [[NSMenu alloc] init];
//    NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:@"Testing..." action:nil keyEquivalent:@""];
//    [recentGamesMenu addItem:menuItem];
//    return recentGamesMenu;
//}

- (void)setDockTile:(NSDockTile *)dockTile {
    if (dockTile) {
        // Attach an observer that will update the high score in the dock tile whenever it changes
        self.updateObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.macenhance.MacForgeDockTileUpdate" object:nil queue:nil usingBlock:^(NSNotification *notification) {
            updateCount(dockTile);
            // Note that this block captures (and retains) dockTile for use later.
            // Also note that it does not capture self, which means -dealloc may be called even while the notification is active.
            // Although it's not clear this needs to be supported, this does eliminate a potential source of leaks.
        }];
        updateCount(dockTile);    // Make sure score is updated from the get-go as well
    } else {
        // Strictly speaking this may not be necessary (since the plug-in may be terminated when it's removed from the dock), but it's good practice
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self.updateObserver];
        self.updateObserver = nil;
    }
}

- (void)dealloc {
    if (self.updateObserver) {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self.updateObserver];
        self.updateObserver = nil;
    }
}

@end
