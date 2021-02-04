//
//  MFPluginLoader.m
//  pluginLoader
//
//  Created by Wolfgang Baird on 2/3/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "MFPluginLoader.h"

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#define SIMBLPluginPath @"Application Support/MacEnhance/Plugins"
#define SIMBLStringTable @"SIMBLStringTable"
#define SIMBLApplicationIdentifier @"SIMBLApplicationIdentifier"
#define SIMBLTargetApplications @"SIMBLTargetApplications"
#define SIMBLBundleIdentifier @"BundleIdentifier"
#define SIMBLMinBundleVersion @"MinBundleVersion"
#define SIMBLMaxBundleVersion @"MaxBundleVersion"
#define SIMBLTargetApplicationPath @"TargetApplicationPath"
#define SIMBLRequiredFrameworks @"RequiredFrameworks"


static void helperMessages (CFNotificationCenterRef center, void * observer, CFStringRef name, const void * object, CFDictionaryRef userInfo) {
    NSDictionary *dictionary = (__bridge NSDictionary *)(userInfo);
    NSLog(@"injectionWatcher : %@", dictionary);
    if (dictionary)
        if ([dictionary valueForKey:@"LOAD"])
            [MFPluginLoader loadPlugins];
}

@implementation MFPluginLoader

+ (void)load {
    NSLog(@"%@ loaded into %@", self.className, NSProcessInfo.processInfo.operatingSystemVersionString);
    [MFPluginLoader loadPlugins];
    CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter();
    CFNotificationCenterAddObserver(center, NULL, helperMessages, CFSTR("com.macenhance.MacForgeHelper.update"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately); // Message from gui
}

+ (void)loadPlugins {
    for (NSString* file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:@"/Library/Application Support/MacEnhance/Plugins/" error:nil]) {
        BOOL loadBundle = false;
        NSString *pluginPath = [@"/Library/Application Support/MacEnhance/Plugins/" stringByAppendingString:file];
        NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
        NSBundle *appBundle = [NSBundle mainBundle];
        NSString *appIdentifier = appBundle.bundleIdentifier;
        NSString *pluginIdentifier = [pluginBundle bundleIdentifier];
        if (pluginIdentifier != nil) {
            // Skip self
            if ([pluginIdentifier isEqualToString:[NSBundle bundleForClass:MFPluginLoader.class].bundleIdentifier]) continue;
            
            NSArray* targetApplications = [pluginBundle objectForInfoDictionaryKey:@"SIMBLTargetApplications"];
            if (targetApplications) {
                for (NSDictionary* targetAppProperties in targetApplications) {
                    NSString* targetAppIdentifier = targetAppProperties[SIMBLBundleIdentifier];
                    if ([targetAppIdentifier isEqualToString:appIdentifier]) loadBundle = true;
                    if ([targetAppIdentifier isEqualToString:@"*"]) loadBundle = true;
//                    NSString* targetAppPath = targetAppProperties[SIMBLTargetApplicationPath];
//                    if ([targetAppPath isEqualToString:appBundle.bundlePath]) loadBundle = true;
//
//                    // Version check
//                    int appVersion = [[appBundle.infoDictionary valueForKey:@"CFBundleVersion"] intValue];
//                    int minVersion = 0;
//                    NSNumber* number;
//                    if ((number = targetAppProperties[SIMBLMinBundleVersion]))
//                        minVersion = number.intValue;
//
//                    int maxVersion = 0;
//                    if ((number = targetAppProperties[SIMBLMaxBundleVersion]))
//                        maxVersion = number.intValue;
//
//                    if (!(maxVersion && appVersion > maxVersion) || !(minVersion && appVersion < minVersion)) loadBundle = false;
                    if (loadBundle) break;
                }
            }
        }
        
        if (loadBundle) [pluginBundle load];
    }
}

@end
