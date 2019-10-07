//
//  DockTilePlugIn.h
//  MacForgeDockTile
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Wolfgang Baird. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DockTilePlugIn : NSObject <NSDockTilePlugIn> {
}
@property(retain) id updateObserver;
@end
