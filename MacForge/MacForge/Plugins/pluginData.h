//
//  pluginData.h
//  MacForge
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <Foundation/Foundation.h>
#import "MSPlugin.h"

@interface pluginData : NSObject

@property NSMutableDictionary *sourceListDic;
@property NSMutableDictionary *repoPluginsDic;
@property NSMutableDictionary *localPluginsDic;
@property MSPlugin *currentPlugin;


+ (pluginData*) sharedInstance;
- (NSMutableDictionary*)fetch_repo:(NSString*)source;
- (void)fetch_repos;
- (void)fetch_local;
- (NSImage*)fetch_icon:(MSPlugin*)plugin;

@end
