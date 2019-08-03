//
//  pluginData.m
//  MacPlus
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

#import "pluginData.h"
#import "PluginManager.h"

@implementation pluginData

+ (pluginData*) sharedInstance {
    static pluginData* pData = nil;
    
    if (pData == nil)
        pData = [[pluginData alloc] init];
    
    return pData;
}

- (instancetype)init {
    if (self = [super init]) {
        _sourceListDic = [[NSMutableDictionary alloc] init];
        _repoPluginsDic = [[NSMutableDictionary alloc] init];
        _localPluginsDic = [[NSMutableDictionary alloc] init];
        _currentPlugin = [[MSPlugin alloc] init];
    }
    return self;
}

- (NSMutableDictionary*)fetch_repo:(NSString*)source {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", source]];
    NSMutableDictionary* repoPackages = [[NSMutableDictionary alloc] initWithContentsOfURL:data];
    if (repoPackages != nil) {
//        NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] init];
//        [sourceDic setObject:repoPackages forKey:@"raw_repoPackages"];
        for (NSString *bundleIdentifier in [repoPackages allKeys]) {
            NSMutableDictionary *bundle = [repoPackages objectForKey:bundleIdentifier];
            [bundle setObject:source forKey:@"sourceURL"];
            
            MSPlugin *this_is_a_bundle = [[MSPlugin alloc] init];
            
            this_is_a_bundle.bundleID = [bundle objectForKey:@"package"];
            this_is_a_bundle.webName = [bundle objectForKey:@"name"];
            this_is_a_bundle.webSize = [bundle objectForKey:@"size"];
            this_is_a_bundle.webPublishDate = [bundle objectForKey:@"date"];
            this_is_a_bundle.webPrice = [bundle objectForKey:@"price"];
            this_is_a_bundle.webTarget = [bundle objectForKey:@"apps"];
            this_is_a_bundle.webRepository = source;
            this_is_a_bundle.webVersion = [bundle objectForKey:@"version"];
            this_is_a_bundle.webDeveloperDonate = [bundle objectForKey:@"donate"];
            this_is_a_bundle.webDeveloperEmail = [bundle objectForKey:@"contact"];
            this_is_a_bundle.webDescription = [bundle objectForKey:@"description"];
            this_is_a_bundle.webDescriptionShort = [bundle objectForKey:@"descriptionShort"];
            this_is_a_bundle.webCompatability = [bundle objectForKey:@"compat"];
            this_is_a_bundle.webFileName = [bundle objectForKey:@"filename"];
            this_is_a_bundle.webPlist = bundle;
            this_is_a_bundle.webPaid = [[bundle valueForKey:@"payed"] boolValue];
            
            
            [result setObject:this_is_a_bundle forKey:bundleIdentifier];
//            [sourceDic setObject:this_is_a_bundle forKey:bundleIdentifier];
        }
    }
    return result;
}

- (void)fetch_repos {
    _sourceListDic = [[NSMutableDictionary alloc] init];
    _repoPluginsDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *sourceURLS = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"]];
    for (NSString *source in sourceURLS) {
        NSURL* data = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", source]];
        NSMutableDictionary* repoPackages = [[NSMutableDictionary alloc] initWithContentsOfURL:data];
        if (repoPackages != nil) {
            NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] init];
            [sourceDic setObject:repoPackages forKey:@"raw_repoPackages"];
            for (NSString *bundleIdentifier in [repoPackages allKeys]) {
                NSMutableDictionary *bundle = [repoPackages objectForKey:bundleIdentifier];
                [bundle setObject:source forKey:@"sourceURL"];
                
                MSPlugin *this_is_a_bundle = [[MSPlugin alloc] init];
                
                this_is_a_bundle.bundleID = [bundle objectForKey:@"package"];
                this_is_a_bundle.webName = [bundle objectForKey:@"name"];
                this_is_a_bundle.webSize = [bundle objectForKey:@"size"];
                this_is_a_bundle.webPublishDate = [bundle objectForKey:@"date"];
                this_is_a_bundle.webPrice = [bundle objectForKey:@"price"];
                this_is_a_bundle.webTarget = [bundle objectForKey:@"apps"];
                this_is_a_bundle.webRepository = source;
                this_is_a_bundle.webVersion = [bundle objectForKey:@"version"];
                this_is_a_bundle.webDeveloperDonate = [bundle objectForKey:@"donate"];
                this_is_a_bundle.webDeveloperEmail = [bundle objectForKey:@"contact"];
                this_is_a_bundle.webDescription = [bundle objectForKey:@"description"];
                this_is_a_bundle.webDescriptionShort = [bundle objectForKey:@"descriptionShort"];
                this_is_a_bundle.webCompatability = [bundle objectForKey:@"compat"];
                this_is_a_bundle.webFileName = [bundle objectForKey:@"filename"];
                this_is_a_bundle.webPlist = bundle;
                this_is_a_bundle.webPaid = [[bundle valueForKey:@"payed"] boolValue];

                
                [self.repoPluginsDic setObject:this_is_a_bundle forKey:bundleIdentifier];
                [sourceDic setObject:this_is_a_bundle forKey:bundleIdentifier];
//                NSLog(@"%@", this_is_a_bundle);
            }
            [self.sourceListDic setObject:sourceDic forKey:source];
        }
    }
}

- (void)fetch_local {
    self.localPluginsDic = [[NSMutableDictionary alloc] init];
    NSArray *folders = [PluginManager MacEnhancePluginPaths];
    for (NSString *str in folders) {
        NSArray *appFolderContents = [[NSArray alloc] init];
        appFolderContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:str error:nil];
        for (NSString* fileName in appFolderContents) {
            if ([fileName hasSuffix:@".bundle"]) {
                NSString *path = [str stringByAppendingPathComponent:fileName];
                NSString *name = [fileName stringByDeletingPathExtension];
                
                NSBundle *bundle = [NSBundle bundleWithPath:path];
                NSString *plistPath = [NSString stringWithFormat:@"%@/Contents/Info.plist", [bundle bundlePath]];
                NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
                
                NSString *bundleIdentifier = [bundle bundleIdentifier];
                
                if (!bundleIdentifier.length)
                    bundleIdentifier = [info objectForKey:@"CFBundleIdentifier"];
                
                if (![bundleIdentifier length])
                    bundleIdentifier = [NSString stringWithFormat:@"(null - %@)", [NSUUID UUID].UUIDString];
                
                NSString *bundleVersion = [info objectForKey:@"CFBundleShortVersionString"];
                if (![bundleVersion length])
                    bundleVersion = [info objectForKey:@"CFBundleVersion"];
                
                Boolean isActive = false;
                Boolean isUser = false;
                NSArray *components = [path pathComponents];
                NSString* location= [components objectAtIndex:1];
                NSString* endcomp= [components objectAtIndex:[components count] - 2];
                NSString *localDescription = [NSString stringWithFormat:@"%@ - %@ - %@", bundleVersion, bundleIdentifier, location];
                if ([location length]) {
                    if (![endcomp rangeOfString:@"Disabled"].length) {
                        isActive = true;
                    } else {
                        localDescription = [NSString stringWithFormat:@"%@ (Disabled)", localDescription];
                    }
                    
                    if (![location rangeOfString:@"Library"].length)
                        isUser = true;
                }
                
                MSPlugin *this_is_a_bundle = [[MSPlugin alloc] init];
                
                this_is_a_bundle.localName = name;
                this_is_a_bundle.bundleID = bundleIdentifier;
                this_is_a_bundle.localVersion = bundleVersion;
                this_is_a_bundle.isInstalled = true;
                this_is_a_bundle.isUser = isUser;
                this_is_a_bundle.isEnabled = isActive;
                this_is_a_bundle.localPlist = info;
                this_is_a_bundle.localPath = path;
                this_is_a_bundle.localDescription = localDescription;
                
                [self.localPluginsDic setObject:this_is_a_bundle forKey:bundleIdentifier];
//                NSLog(@"%@", this_is_a_bundle.bundleInfoPlist);
            }
        }
    }
}

- (NSImage*)fetch_icon:(MSPlugin*)plugin {
    NSImage* result = nil;
    NSArray* targets = [[NSArray alloc] init];
    targets = [plugin.localPlist objectForKey:@"SIMBLTargetApplications"];
    NSString* iconPath = [NSString stringWithFormat:@"%@/Contents/icon.icns", plugin.localPath];
    NSString* iconFile = [plugin.localPlist objectForKey:@"CFBundleIconFile"];
    
    if ([iconFile length])
        iconPath = [NSString stringWithFormat:@"%@/Contents/Resources/%@.icns", plugin.localPath, iconFile];
    
    if ([iconPath length]) {
        result = [[NSImage alloc] initWithContentsOfFile:iconPath];
        if (result) return result;
    }
    
//    NSData *defaultIcon = [[[NSWorkspace sharedWorkspace] iconForFile:@"/System/Library/CoreServices/loginwindow.app"] TIFFRepresentation];
    for (NSDictionary* targetApp in targets) {
        iconPath = [targetApp objectForKey:@"BundleIdentifier"];
        iconPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:iconPath];
        
        if ([iconPath length]) {
            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.notificationcenterui"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Notifications.icns"];
                if (result) return result;
            }

            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.systemuiserver"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/Assistant.icns"];
                if (result) return result;
            }

            if ([[targetApp objectForKey:@"BundleIdentifier"] isEqualToString:@"com.apple.loginwindow"]) {
                result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GroupIcon.icns"];
                if (result) return result;
            }

            result = [[NSWorkspace sharedWorkspace] iconForFile:iconPath];
//            NSData *appIcon = [result TIFFRepresentation];
//            if (![defaultIcon isEqualToData:appIcon])
                return result;
        }
    }
    
    result = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
    return result;
}

@end
