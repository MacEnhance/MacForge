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

+ (void)pushthebutton:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo {
    if ([MF_Purchase packageInstalled:plugin]) {
        if ([theButton.title isEqualToString:@"Update"]) {
            // Installed, update
            [MF_Purchase pluginInstall:plugin :theButton :repo];
        } else if ([theButton.title isEqualToString:@"Downgrade"]) {
            // Installed, downgrade
            [MF_Purchase pluginInstall:plugin :theButton :repo];
        } else {
            // Installed, reveal in Finder
            [PluginManager.sharedInstance pluginRevealFinder:plugin.webPlist];
        }
    } else {
        // Not installed try to purchase or install
        [MF_Purchase installOrPurchase:plugin :theButton :repo];
    }
}

+ (void)verifyPurchased:(MSPlugin*)plugin :(NSButton*)theButton {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary* item = plugin.webPlist;
    NSString *productID = [item objectForKey:@"productID"];
    if (productID != nil) {
        Paddle *thePaddle = myDelegate.thePaddle;
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";
        
        // Populate a local object in case we're unable to retrieve data from the Vendor Dashboard:
        PADProductConfiguration *defaultProductConfig = [[PADProductConfiguration alloc] init];
        defaultProductConfig.productName = @"plugin";
        defaultProductConfig.vendorName = @"macenhance";
        
        // Initialize the SDK Instance with Seller details:
        thePaddle = [Paddle sharedInstanceWithVendorID:myPaddleVendorID
                                                apiKey:myPaddleAPIKey
                                             productID:productID
                                         configuration:defaultProductConfig
                                              delegate:myDelegate];
        
        // Initialize the Product you'd like to work with:
        PADProduct *paddleProduct = [[PADProduct alloc] initWithProductID:productID productType:PADProductTypeSDKProduct configuration:defaultProductConfig];
        
        // Ask the Product to get it's latest state and info from the Paddle Platform:
        [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
            if ([paddleProduct activated]) {
                theButton.title = @"Install";
            } else {
                theButton.title = plugin.webPrice;
            }
        }];
    } else {
        NSLog(@"No product info ???");
    }
}

+ (Boolean)packageInstalled:(MSPlugin*)plugin {
    NSLog(@"Hmmmm...");
    NSDictionary* item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [PluginManager.sharedInstance getInstalledPlugins];
    if ([installedPlugins objectForKey:[item objectForKey:@"package"]])
        return true;
    return false;
}

+ (void)checkStatus:(MSPlugin*)plugin :(NSButton*)theButton {
    NSDictionary* item = plugin.webPlist;
    NSMutableDictionary *installedPlugins = [PluginManager.sharedInstance getInstalledPlugins];
    if ([installedPlugins objectForKey:[item objectForKey:@"package"]]) {
        // Pack already exists
//        [self.bundleDelete setEnabled:true];
        NSDictionary* dic = [[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"];
        NSString* cur = [dic objectForKey:@"CFBundleShortVersionString"];
        if ([cur isEqualToString:@""])
            cur = [dic objectForKey:@"CFBundleVersion"];
        NSString* new = [item objectForKey:@"version"];
        id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
        NSInteger result = [comparator compareVersion:cur toVersion:new];
        if (result == NSOrderedSame) {
            //versionA == versionB
            theButton.title = @"Open";
//            [theButton setAction:@selector(pluginFinder)];
        } else if (result == NSOrderedAscending) {
            //versionA < versionB
            theButton.title = @"Update";
//            [theButton setAction:@selector(pluginInstall)];
        } else {
            //versionA > versionB
            theButton.title = @"Downgrade";
//            [theButton setAction:@selector(pluginInstall)];
        }
    } else {
        // Package not installed
        [MF_Purchase verifyPurchased:plugin :theButton];
    }
}

+ (void)installOrPurchase:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSDictionary* item = plugin.webPlist;
    NSString *productID = [item objectForKey:@"productID"];
    if (productID != nil) {
        Paddle *thePaddle = myDelegate.thePaddle;
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";
        
        // Populate a local object in case we're unable to retrieve data from the Vendor Dashboard:
        PADProductConfiguration *defaultProductConfig = [[PADProductConfiguration alloc] init];
        defaultProductConfig.productName = @"plugin";
        defaultProductConfig.vendorName = @"macenhance";
        
        // Initialize the SDK Instance with Seller details:
        thePaddle = [Paddle sharedInstanceWithVendorID:myPaddleVendorID
                                                apiKey:myPaddleAPIKey
                                             productID:productID
                                         configuration:defaultProductConfig
                                              delegate:myDelegate];
        
        // Initialize the Product you'd like to work with:
        PADProduct *paddleProduct = [[PADProduct alloc] initWithProductID:productID productType:PADProductTypeSDKProduct configuration:defaultProductConfig];
        
        [thePaddle setCanForceExit:false];
        
        // Ask the Product to get it's latest state and info from the Paddle Platform:
        [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
            if ([paddleProduct activated]) {
                [MF_Purchase pluginInstall:plugin :theButton :repo];
            } else {
                [thePaddle showCheckoutForProduct:paddleProduct options:nil checkoutStatusCompletion:^(PADCheckoutState state, PADCheckoutData * _Nullable checkoutData) {
                    // Examine checkout state to determine the checkout result
                    if (state == PADCheckoutPurchased) {
                        [MF_Purchase pluginInstall:plugin :theButton :repo];
                    } else {
                        [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
                            if ([paddleProduct activated])
                                [MF_Purchase pluginInstall:plugin :theButton :repo];
                            NSLog(@"activated : %hhd", [paddleProduct activated]);
                        }];
                    }
                }];
            }
        }];
    } else {
        NSLog(@"No product info... lets assume it's FREEEE");
        [MF_Purchase pluginInstall:plugin :theButton :repo];
    }
}

+ (void)pluginInstall:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo {
    NSDictionary* item = plugin.webPlist;
    [PluginManager.sharedInstance pluginUpdateOrInstall:item :repo];
    dispatch_async(dispatch_get_main_queue(), ^{
        [PluginManager.sharedInstance readPlugins:nil];
        [theButton setTitle:@"Open"];
    });
}

@end
