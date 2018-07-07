//
//  shareClass.h
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@interface shareClass : NSObject

+ (shareClass*) sharedInstance;

- (void)checkforPluginUpdates:(NSTableView*)table;

- (void)readPlugins:(NSTableView *)pluginTable;
- (void)replaceFile:(NSString*)start :(NSString*)end;
- (void)installBundles:(NSArray*)pathArray;

- (void)pluginInstall:(NSDictionary*)item :(NSString*)repo;
- (void)pluginUpdate:(NSDictionary*)item :(NSString*)repo;
- (void)pluginDelete:(NSDictionary*)item;

- (NSImage*)getbundleIcon:(NSDictionary*)plist;

- (Boolean)keypressed:(NSEvent *)theEvent;

@end
