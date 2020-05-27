//
//  MF_Purchase.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;

#import "MF_PluginManager.h"
#import "MF_repoData.h"
#import "MF_Purchase.h"

#import "AppDelegate.h"

extern AppDelegate* myDelegate;

@implementation MF_Purchase

+ (void)pushthebutton:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator*)progress {
    if ([MF_Purchase packageInstalled:plugin]) {
        if ([theButton.title isEqualToString:@"UPDATE"]) {
            // Installed, update
            [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
            [MSAnalytics trackEvent:@"Update" withProperties:@{@"Product ID" : plugin.bundleID}];
        } else if ([theButton.title isEqualToString:@"UPDATE"]) {
            // Installed, downgrade
            [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
            [MSAnalytics trackEvent:@"Downgrade" withProperties:@{@"Product ID" : plugin.bundleID}];
        } else {
            // Installed, reveal in Finder
            [MF_PluginManager.sharedInstance pluginRevealFinder:plugin.webPlist];
            [MSAnalytics trackEvent:@"Open" withProperties:@{@"Product ID" : plugin.bundleID}];
        }
    } else {
        // Not installed try to purchase or install
        [MF_Purchase installOrPurchase:plugin :theButton :repo :progress];
    }
}

+ (void)verifyPurchased:(MF_Plugin*)plugin :(NSButton*)theButton {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
//    NSLog(@"%@ : %@", plugin.bundleID, theButton);
    
    if (plugin.checkedPurchase) {
    
        if (plugin.hasPurchased) {
            
//            NSLog(@"%@ is purchased", plugin.bundleID);
            dispatch_async(dispatch_get_main_queue(), ^{
                theButton.enabled = true;
                theButton.title = @"GET";
                theButton.toolTip = @"";
            });
            
        } else {
            
//            NSLog(@"%@ is not purchased", plugin.bundleID);
            dispatch_async(dispatch_get_main_queue(), ^{
                theButton.enabled = true;
                theButton.title = plugin.webPrice;
                theButton.toolTip = @"";
            });
            
        }
    
    } else {
        
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
                    plugin.checkedPurchase = true;
                    if ([task terminationStatus] == 69) {
                        plugin.hasPurchased = true;
                        NSLog(@"Verified... %@", plugin.bundleID);
                        theButton.title = @"GET";
                        theButton.toolTip = @"";
                    } else {
                        plugin.hasPurchased = false;
                        theButton.title = plugin.webPrice;
                        theButton.toolTip = @"";
                    }
                    theButton.enabled = true;
                });
            });
        }
            
    }
}

+ (Boolean)packageInstalled:(MF_Plugin*)plugin {
    if ([MF_PluginManager.sharedInstance pluginLocalPath:plugin.bundleID].length)
        return true;
    return false;
}

+ (void)checkStatus:(MF_Plugin*)plugin :(NSButton*)theButton {
    NSDictionary* item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [MF_PluginManager.sharedInstance getInstalledPlugins];
//
//    Boolean installed = false;
    NSString *bundleID = [item objectForKey:@"package"];
    NSString *type = [item objectForKey:@"type"];
//
//    if ([installedPlugins objectForKey:bundleID])
//        installed = true;
//
//    if ([Workspace URLForApplicationWithBundleIdentifier:bundleID]) {
//        if ([[Workspace URLForApplicationWithBundleIdentifier:bundleID].path.pathComponents.firstObject isEqualToString:@"/Applications"])
//            installed = true;
//    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        theButton.enabled = true;
    });
    
    if ([MF_PluginManager.sharedInstance pluginLocalPath:bundleID].length) {
        // Pack already exists
        
        NSString *cur;
        if ([type isEqualToString:@"app"]) {
            NSString *path = [Workspace absolutePathForAppBundleWithIdentifier:bundleID];
            path = [path stringByAppendingString:@"/Contents/Info.plist"];
//            NSLog(@"------ %@", path);
            NSDictionary* dic = [[NSDictionary alloc] initWithContentsOfFile:path];
            cur = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([cur isEqualToString:@""])
                cur = [dic objectForKey:@"CFBundleVersion"];
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
                theButton.toolTip = @"";
            } else if (result == NSOrderedAscending) {
                //versionA < versionB --- Update
                theButton.title = @"⬆";
                theButton.toolTip = @"Update";
            } else {
                //versionA > versionB --- Downgrade
                theButton.title = @"⬇";
                theButton.toolTip = @"Downgrade";
//                theButton.enabled = false;
            }
        });
    } else {
        // Package not installed
        [MF_Purchase verifyPurchased:plugin :theButton];
    }
}

+ (void)installOrPurchase:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator*)progress {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSDictionary* item = plugin.webPlist;
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        [MSAnalytics trackEvent:@"Purchase Attempt" withProperties:@{@"Product" : plugin.webName, @"Product ID" : myPaddleProductID}];
        
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
                   plugin.hasPurchased = true;
                   [MSAnalytics trackEvent:@"Purchased Product" withProperties:@{@"Product" : plugin.webName, @"Product ID" : myPaddleProductID}];
                   [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
               } else {
                   NSLog(@"Purchase canceled or failed.");
               }
           });
        });
    } else {
        NSLog(@"No product info... lets assume it's FREEEE");
        [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
        [MSAnalytics trackEvent:@"Install" withProperties:@{@"Product ID" : plugin.bundleID}];
    }
}

+ (void)pluginInstallWithProgress:(MF_Plugin*)plugin :(NSString*)repo :(NSButton*)theButton :(NSProgressIndicator*)progress {
//    NSLog(@"%@", progress);
    if (progress) {
        NSDictionary* item = plugin.webPlist;
        [MF_PluginManager.sharedInstance pluginUpdateOrInstallWithProgress:item :repo :theButton :progress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MF_PluginManager.sharedInstance readPlugins:nil];
            [theButton setTitle:@"OPEN"];
        });
    } else {
        [MF_Purchase pluginInstall:plugin :theButton :repo];
    }
}

+ (void)pluginInstall:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo {
   NSDictionary* item = plugin.webPlist;
    [MF_PluginManager.sharedInstance pluginUpdateOrInstall:item :repo withCompletionHandler:^(BOOL res) {
        [MF_PluginManager.sharedInstance readPlugins:nil];
        [theButton setTitle:@"OPEN"];
    }];
}

@end
