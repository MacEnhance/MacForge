//
//  PluginManager.h
//  PluginManager
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@interface MF_PluginManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate> {
    NSMutableArray      *pluginsArray;
    NSMutableDictionary *installedPluginDICT;
    NSMutableDictionary *needsUpdate;
    
    NSButton            *downloadButton;
    NSProgressIndicator *progressObject;
}

@property (nonatomic, retain) NSMutableData *dataToDownload;
@property (nonatomic) float downloadSize;
@property (nonatomic, retain) NSDictionary *plugin;

+ (MF_PluginManager*) sharedInstance;
+ (NSArray*)MacEnhancePluginPaths;
+ (NSImage*)pluginGetIcon:(NSDictionary*)plist;

- (NSString*)pluginLocalPath:(NSString*)bundleID;

- (NSMutableDictionary*)getInstalledPlugins;

- (NSMutableDictionary*)getNeedsUpdate;
- (void)checkforPluginUpdates:(NSTableView*)table :(NSButton*)counter;
- (void)checkforPluginUpdates:(NSTableView*)table;
- (void)checkforPluginUpdatesAndInstall:(NSTableView*)table;
- (NSUserNotification*)checkforPluginUpdatesNotify;

- (void)readPlugins:(NSTableView *)pluginTable;

- (void)installBundles:(NSArray*)pathArray;
- (void)replaceFile:(NSString*)start :(NSString*)end;
- (Boolean)pluginUpdateOrInstall:(NSDictionary*)item :(NSString*)repo withCompletionHandler:(void (^)(BOOL))completionBlock;
- (Boolean)pluginDelete:(NSDictionary*)item;
- (Boolean)pluginRevealFinder:(NSDictionary*)item;

- (Boolean)pluginUpdateOrInstallWithProgress:(NSDictionary *)item :(NSString *)repo :(NSButton *)button :(NSProgressIndicator *)progress;

@end
