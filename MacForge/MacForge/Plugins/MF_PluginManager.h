//
//  PluginManager.h
//  PluginManager
//
//  Created by Wolfgang Baird on 3/13/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@interface MF_PluginManager : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSUserNotificationCenterDelegate> {
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
- (NSString*)getItemLocalVersion:(NSString*)bundleID;

- (NSMutableDictionary*)getInstalledPlugins;

- (NSMutableDictionary*)getNeedsUpdate;
- (void)checkforPluginUpdates:(NSTableView*)table;
- (void)checkforPluginUpdates:(NSTableView*)table :(NSButton*)counter;
- (void)checkforPluginUpdatesAndInstall:(NSTableView*)table;

- (void)installBundles:(NSArray*)pathArray;
- (void)readPlugins:(NSTableView *)pluginTable;
- (void)replaceFile:(NSString*)start :(NSString*)end;

- (Boolean)pluginDelete:(NSDictionary*)item;
- (Boolean)pluginRevealFinder:(NSDictionary*)item;
- (Boolean)pluginUpdateOrInstall:(NSDictionary*)item withCompletionHandler:(void (^)(BOOL))completionBlock;
- (Boolean)pluginUpdateOrInstall:(NSDictionary *)item withButton:(NSButton *)button andProgress:(NSProgressIndicator *)progress;

@end
