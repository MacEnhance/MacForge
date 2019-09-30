//
//  MF_Purchase.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;

#import "PluginManager.h"
#import "pluginData.h"
#import "MF_Purchase.h"

#import "AppDelegate.h"

extern AppDelegate* myDelegate;

@implementation MF_Purchase

+ (void)pushthebutton:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator*)progress {
    if ([MF_Purchase packageInstalled:plugin]) {
        if ([theButton.title isEqualToString:@"UPDATE"]) {
            // Installed, update
            [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
        } else if ([theButton.title isEqualToString:@"UPDATE"]) {
            // Installed, downgrade
            [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
        } else {
            // Installed, reveal in Finder
            [PluginManager.sharedInstance pluginRevealFinder:plugin.webPlist];
        }
    } else {
        // Not installed try to purchase or install
        [MF_Purchase installOrPurchase:plugin :theButton :repo :progress];
    }
}

+ (void)verifyPurchased:(MSPlugin*)plugin :(NSButton*)theButton {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@ : %@", plugin.bundleID, theButton);
    
    NSDictionary* item = plugin.webPlist;
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";

        NSDictionary *dict = [plugin.webPlist objectForKey:@"paddle"];
        if (dict != nil) {
            myPaddleVendorID = [dict objectForKey:@"vendorid"];
            myPaddleAPIKey = [dict objectForKey:@"apikey"];
//            NSLog(@"Hello %@ : %@ : %@ : %@",plugin.bundleID, myPaddleProductID,myPaddleVendorID,myPaddleAPIKey);
        }
    
        NSBundle *b = [NSBundle mainBundle];
        NSString *execPath = [b pathForResource:@"purchaseValidationApp" ofType:@"app"];
        execPath = [NSString stringWithFormat:@"%@/Contents/MacOS/purchaseValidationApp", execPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSLog(@"Hello %@ : %@ : %@ : %@",plugin.bundleID, myPaddleProductID,myPaddleVendorID,myPaddleAPIKey);
            NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[myPaddleProductID, myPaddleVendorID, myPaddleAPIKey, @"-v"]];
            [task waitUntilExit];
         
           //This is your completion handler
           dispatch_sync(dispatch_get_main_queue(), ^{
               if ([task terminationStatus] == 69) {
                    NSLog(@"Verified... %@", plugin.bundleID);
                    theButton.title = @"GET";
                } else {
                    theButton.title = plugin.webPrice;
                }
           });
        });
    }
}

+ (Boolean)packageInstalled:(MSPlugin*)plugin {
    NSDictionary* item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [PluginManager.sharedInstance getInstalledPlugins];
    NSString *bundleID = [item objectForKey:@"package"];
    
    // Bundle
    if ([installedPlugins objectForKey:bundleID])
        return true;
    
    // Application
    if ([Workspace URLForApplicationWithBundleIdentifier:bundleID])
        return true;
    
    return false;
}

+ (void)checkStatus:(MSPlugin*)plugin :(NSButton*)theButton {
    NSDictionary* item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [PluginManager.sharedInstance getInstalledPlugins];
    
    Boolean installed = false;
    NSString *bundleID = [item objectForKey:@"package"];
    NSString *type = [item objectForKey:@"type"];
    
    if ([installedPlugins objectForKey:bundleID])
        installed = true;
    
    if ([Workspace URLForApplicationWithBundleIdentifier:bundleID])
        installed = true;
        
    if (installed) {
        // Pack already exists
        
        NSString *cur;
        if ([type isEqualToString:@"app"]) {
//            NSLog(@"------ %@", [Workspace URLForApplicationWithBundleIdentifier:bundleID]);
            NSString *path = [Workspace absolutePathForAppBundleWithIdentifier:bundleID];
            path = [path stringByAppendingString:@"/Contents/Info.plist"];
//            NSLog(@"------ %@", path);

            NSDictionary* dic = [[NSDictionary alloc] initWithContentsOfFile:path];
            cur = [dic objectForKey:@"CFBundleShortVersionString"];
//            NSLog(@"------ %@", cur);
        } else {
            NSDictionary* dic = [[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"];
            cur = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([cur isEqualToString:@""])
                cur = [dic objectForKey:@"CFBundleVersion"];
        }
                
        NSString* new = [item objectForKey:@"version"];
        id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
        NSInteger result = [comparator compareVersion:cur toVersion:new];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (result == NSOrderedSame) {
                //versionA == versionB --- Twinnning
                theButton.title = @"OPEN";
            } else if (result == NSOrderedAscending) {
                //versionA < versionB --- Update
                theButton.title = @"UPDATE";
            } else {
                //versionA > versionB --- Downgrade
                theButton.title = @"UPDATE";
            }
        });
    } else {
        // Package not installed
        [MF_Purchase verifyPurchased:plugin :theButton];
    }
}

+ (void)installOrPurchase:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator*)progress {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSDictionary* item = plugin.webPlist;
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";

        NSDictionary *dict = [plugin.webPlist objectForKey:@"paddle"];
        if (dict != nil) {
            myPaddleVendorID = [dict objectForKey:@"vendorid"];
            myPaddleAPIKey = [dict objectForKey:@"apikey"];
        }
    
        NSBundle *b = [NSBundle mainBundle];
        NSString *execPath = [b pathForResource:@"purchaseValidationApp" ofType:@"app"];
        execPath = [NSString stringWithFormat:@"%@/Contents/MacOS/purchaseValidationApp", execPath];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSLog(@"Hello %@ %@ %@",myPaddleProductID,myPaddleVendorID,myPaddleAPIKey);
            NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[myPaddleProductID, myPaddleVendorID, myPaddleAPIKey]];
            [task waitUntilExit];
         
           //This is your completion handler
           dispatch_sync(dispatch_get_main_queue(), ^{
               if ([task terminationStatus] == 69) {
                    [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
                } else {
                    NSLog(@"Purchase canceled or failed.");
                }
           });
        });
    } else {
        NSLog(@"No product info... lets assume it's FREEEE");
        [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
    }
}

+ (void)pluginInstallWithProgress:(MSPlugin*)plugin :(NSString*)repo :(NSButton*)theButton :(NSProgressIndicator*)progress {
    NSLog(@"%@", progress);
    if (progress) {
        NSDictionary* item = plugin.webPlist;
        [PluginManager.sharedInstance pluginUpdateOrInstallWithProgress:item :repo :theButton :progress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [PluginManager.sharedInstance readPlugins:nil];
            [theButton setTitle:@"OPEN"];
        });
    } else {
        [MF_Purchase pluginInstall:plugin :theButton :repo];
    }
}

+ (void)pluginInstall:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo {
    NSDictionary* item = plugin.webPlist;
    [PluginManager.sharedInstance pluginUpdateOrInstall:item :repo];
    dispatch_async(dispatch_get_main_queue(), ^{
        [PluginManager.sharedInstance readPlugins:nil];
        [theButton setTitle:@"OPEN"];
    });
}

@end
