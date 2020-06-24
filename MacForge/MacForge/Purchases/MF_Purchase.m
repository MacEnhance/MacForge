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
#import "MF_Paddle.h"

#import "AppDelegate.h"

extern AppDelegate* myDelegate;

@implementation MF_Purchase

+ (void)pushthebutton:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator*)progress {
    if ([MF_Purchase packageInstalled:plugin]) {
        NSArray *updoot = @[@"UPDATE", @"⬆", @"⬇"];
        if ([updoot containsObject:theButton.title]) {
            // Updating or downgrading
            [MF_Purchase pluginInstall:plugin withButton:theButton andProgress:progress];
            [MSAnalytics trackEvent:@"Update" withProperties:@{@"Product ID" : plugin.bundleID}];
        } else {
            // Installed, reveal in Finder
            [MF_PluginManager.sharedInstance pluginRevealFinder:plugin.webPlist];
            [MSAnalytics trackEvent:@"Open" withProperties:@{@"Product ID" : plugin.bundleID}];
        }
    } else {
        // Not installed try to purchase or install
        [MF_Purchase installOrPurchase:plugin :theButton :progress];
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
    NSString            *bundleID = item[@"package"];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        theButton.enabled = true;
    });

    // Pack already installed
    if (isInstalled) {
        NSString *cur = [MF_PluginManager.sharedInstance getItemLocalVersion:bundleID];
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
            
            if ([item objectForKey:@"productID"] != nil) {
                if (!isInstalled) dispatch_async(dispatch_get_main_queue(), ^{ theButton.title = @"..."; });
                [MF_Paddle validadePlugin:plugin withButton:theButton];
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

+ (void)installOrPurchase:(MF_Plugin*)plugin :(NSButton*)theButton :(NSProgressIndicator*)progress {
    NSDictionary* item = plugin.webPlist;
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        [MSAnalytics trackEvent:@"Purchase Attempt" withProperties:@{@"Product" : plugin.webName, @"Product ID" : myPaddleProductID}];
        [MF_Paddle purchasePlugin:plugin withButton:theButton andProgress:progress];
    } else {
        NSLog(@"No product info... lets assume it's FREEEE");
        [MSAnalytics trackEvent:@"Install" withProperties:@{@"Product ID" : plugin.bundleID}];
        [MF_Purchase pluginInstall:plugin withButton:theButton andProgress:progress];
    }
}

+ (void)pluginInstall:(MF_Plugin*)plugin withButton:(NSButton*)theButton andProgress:(NSProgressIndicator*)progress {
    if (progress) {
        [MF_PluginManager.sharedInstance pluginUpdateOrInstall:plugin.webPlist withButton:theButton andProgress:progress];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MF_PluginManager.sharedInstance readPlugins:nil];
            [theButton setTitle:@"OPEN"];
        });
    } else {
        [MF_Purchase pluginInstall:plugin :theButton];
    }
}

+ (void)pluginInstall:(MF_Plugin*)plugin :(NSButton*)theButton {
    [MF_PluginManager.sharedInstance pluginUpdateOrInstall:plugin.webPlist withCompletionHandler:^(BOOL res) {
        [MF_PluginManager.sharedInstance readPlugins:nil];
        [theButton setTitle:@"OPEN"];
    }];
}

@end
