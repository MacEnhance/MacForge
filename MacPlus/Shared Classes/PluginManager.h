//
//  shareClass.h
//  mySIMBL
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@interface PluginManager : NSObject {
    NSMutableArray *pluginsArray;
    NSMutableArray *confirmDelete;
    NSMutableDictionary *installedPluginDICT;
    NSMutableDictionary *needsUpdate;
}

+ (PluginManager*) sharedInstance;
+ (NSArray*)SIMBLPaths;
+ (NSImage*)pluginGetIcon:(NSDictionary*)plist;

- (NSMutableDictionary*)getInstalledPlugins;

- (NSMutableDictionary*)getNeedsUpdate;
- (void)checkforPluginUpdates:(NSTableView*)table :(NSButton*)counter;
- (void)checkforPluginUpdates:(NSTableView*)table;
- (void)checkforPluginUpdatesAndInstall:(NSTableView*)table;

- (void)readPlugins:(NSTableView *)pluginTable;

- (void)installBundles:(NSArray*)pathArray;
- (void)replaceFile:(NSString*)start :(NSString*)end;
- (Boolean)pluginUpdateOrInstall:(NSDictionary*)item :(NSString*)repo;
- (Boolean)pluginDelete:(NSDictionary*)item;
- (Boolean)pluginRevealFinder:(NSDictionary*)item;

@end
