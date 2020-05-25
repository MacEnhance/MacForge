//
//  MF_repoData.h
//  MacForge
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <Foundation/Foundation.h>
#import "MF_Plugin.h"

@interface MF_repoData : NSObject

@property MF_Plugin             *currentPlugin;
@property NSMutableDictionary   *repoPluginsDic;
@property NSMutableDictionary   *localPluginsDic;
@property Boolean               hasFetched;

+ (MF_repoData*) sharedInstance;
- (NSMutableDictionary*)fetch_repo:(NSString*)source;
- (NSMutableArray*)fetch_featured:(NSString*)source;
- (void)fetch_repos;
- (void)fetch_local;
- (NSImage*)fetch_icon:(MF_Plugin*)plugin;

@end
