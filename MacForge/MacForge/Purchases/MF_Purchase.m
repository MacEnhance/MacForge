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
        NSArray *updoot = @[@"UPDATE", @"⬆", @"⬇"];
        if ([updoot containsObject:theButton.title]) {
            // Updating or downgrading
            [MF_Purchase pluginInstallWithProgress:plugin :repo :theButton :progress];
            [MSAnalytics trackEvent:@"Update" withProperties:@{@"Product ID" : plugin.bundleID}];
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

+ (Boolean)packageInstalled:(MF_Plugin*)plugin {
    if ([MF_PluginManager.sharedInstance pluginLocalPath:plugin.bundleID].length)
        return true;
    return false;
}

+ (void)checkStatus:(MF_Plugin*)plugin :(NSButton*)theButton {
    
    NSString            *localPath = [MF_PluginManager.sharedInstance pluginLocalPath:plugin.bundleID];
    Boolean             isInstalled = localPath.length;
    NSDictionary        *item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [MF_PluginManager.sharedInstance getInstalledPlugins];
    NSString            *bundleID = item[@"package"];
    NSString            *type = item[@"type"];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        theButton.enabled = true;
    });

    // Pack already installed
    if (isInstalled) {
        NSString *cur;
        if ([type isEqualToString:@"app"]) {
            
            NSString *path = [Workspace absolutePathForAppBundleWithIdentifier:bundleID];
            path = [path stringByAppendingString:@"/Contents/Info.plist"];
            NSDictionary* dic = [[NSDictionary alloc] initWithContentsOfFile:path];
            cur = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([cur isEqualToString:@""])
                cur = [dic objectForKey:@"CFBundleVersion"];
            
        } else if ([type isEqualToString:@"cape"]) {
            
            NSString *capeFolder = [@"~/Library/Application Support/Mousecape/capes" stringByExpandingTildeInPath];
            NSString* capePath = [capeFolder stringByAppendingFormat:@"/%@.cape", bundleID];
            
            for (NSString* file in [FileManager contentsOfDirectoryAtPath:capeFolder error:nil])
                if ([file containsString:bundleID])
                    capePath = [capeFolder stringByAppendingFormat:@"/%@", file];
            
            if ([FileManager fileExistsAtPath:capePath]) {
                NSDictionary *d = [[NSDictionary alloc] initWithContentsOfFile:capePath];
                NSObject *test = d[@"CapeVersion"];
                cur = [NSString stringWithFormat:@"%@", test];
            }
            
        } else {
            NSDictionary* dic = [[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"];
            cur = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([cur isEqualToString:@""])
                cur = [dic objectForKey:@"CFBundleVersion"];
        }
                
        NSString* new = [item objectForKey:@"version"];
        id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
        NSInteger result = [comparator compareVersion:cur toVersion:new];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result == NSOrderedSame) {
                theButton.title = @"OPEN";
                theButton.toolTip = @"";
            } else if (result == NSOrderedAscending) {
                theButton.title = @"⬆";
                theButton.toolTip = @"Update";
            } else {
                theButton.title = @"⬇";
                theButton.toolTip = @"Downgrade";
            }
        });
    }
    
    // Paid
    if (plugin.webPaid) {
        // has checked for purchase
        if (plugin.checkedPurchase) {
            // not installed
            if (!isInstalled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    theButton.enabled = true;
                    theButton.toolTip = @"";
                    theButton.title = @"GET";
                    if (!plugin.hasPurchased)
                        theButton.title = plugin.webPrice;
                });
            }
        } else {
            
//            NSDictionary* item = plugin.webPlist;
            NSString *myPaddleProductID = [item objectForKey:@"productID"];
            if (myPaddleProductID != nil) {
                if (!isInstalled) dispatch_async(dispatch_get_main_queue(), ^{ theButton.title = @"..."; });
                
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
                    NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[myPaddleProductID, myPaddleVendorID, myPaddleAPIKey, @"-v"]];
                    [task waitUntilExit];
                 
                    //This is your completion handler
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        plugin.checkedPurchase = true;
                        if ([task terminationStatus] == 69) {
                            plugin.hasPurchased = true;
                            NSLog(@"Verified... %@", plugin.bundleID);
                            if (!isInstalled) {
                                theButton.title = @"GET";
                                theButton.toolTip = @"";
                            }
                        } else {
                            plugin.hasPurchased = false;
                            if (!isInstalled) {
                                theButton.title = plugin.webPrice;
                                theButton.toolTip = @"";
                            }
                        }
                        theButton.enabled = true;
                    });
                });
            }
            
        }
        
    } else {
        
        // not installed
        if (!isInstalled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                theButton.enabled = true;
                theButton.toolTip = @"";
                theButton.title = @"GET";
            });
        }
        
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
