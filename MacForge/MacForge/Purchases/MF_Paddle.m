//
//  MF_Purchase.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
#import "AppDelegate.h"
#import "MF_PluginManager.h"
#import "MF_repoData.h"
#import "MF_Purchase.h"
#import "MF_Paddle.h"

extern AppDelegate* myDelegate;

@interface Paddle ()

@property (nonnull, copy) NSString *vendorID;
@property (nonnull, copy) NSString *apiKey;
@property (nonnull, copy) NSString *productID;

@end

@interface MF_Paddle () <PaddleDelegate>
@end

@implementation MF_Paddle

- (NSString *)customStoragePath {
    return @"/Users/Shared/macenhance";
}

- (void)didDismissPaddleUIType:(PADUIType)uiType triggeredUIType:(PADTriggeredUIType)triggeredUIType product:(nonnull PADProduct *)product {
    NSLog(@"%ld : %ld : %@", (long)uiType, (long)triggeredUIType, product);
    switch (triggeredUIType) {
        case PADTriggeredUITypeCancel:
            // Quit pressed
            myDelegate.dontKillMe = true;
            return;
        case PADTriggeredUITypeContinueTrial:
            break;
        case PADTriggeredUITypeShowProductAccess:
            break;
        case PADTriggeredUITypeShowCheckout:
            break;
        case PADTriggeredUITypeShowActivate:
            break;
        case PADTriggeredUITypeActivated:
            break;
        case PADTriggeredUITypeDeactivated:
            break;
        case PADTriggeredUITypeFinished:
            break;
    }
}

- (PADDisplayConfiguration *)willShowPaddleUIType:(PADUIType)uiType
                                          product:(PADProduct *)product {
    // We'll unconditionally display all configurable Paddle dialogs as sheets attached to the main window.
    return [PADDisplayConfiguration configuration:PADDisplayTypeSheet
                            hideNavigationButtons:NO
                                     parentWindow:myDelegate.window];
}

+ (instancetype)sharedInstance {
    static MF_Paddle *pad = nil;
    @synchronized(self) {
        if (!pad) {
            pad = [[self alloc] init];
        }
    }
    return pad;
}

+ (PADProduct*)productWithPlugin:(MF_Plugin*)plugin {
    NSString *myPaddleVendorID = @"26643";
    NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";
    NSString *myPaddleProductID = [plugin.webPlist valueForKey:@"productID"];

    NSDictionary *dict = [plugin.webPlist objectForKey:@"paddle"];
    if (dict != nil) {
        myPaddleVendorID = [dict objectForKey:@"vendorid"];
        myPaddleAPIKey = [dict objectForKey:@"apikey"];
    }
    
    // Populate a local object in case we're unable to retrieve data from the Vendor Dashboard:
    PADProductConfiguration *defaultProductConfig = [[PADProductConfiguration alloc] init];
    defaultProductConfig.productName = @"plugin";
    defaultProductConfig.vendorName = @"macenhance";

    if (!Paddle.sharedInstance) {
        [Paddle sharedInstanceWithVendorID:myPaddleVendorID
                                    apiKey:myPaddleAPIKey
                                 productID:myPaddleProductID
                             configuration:defaultProductConfig
                                  delegate:MF_Paddle.sharedInstance];
    } else {
        Paddle.sharedInstance.vendorID = myPaddleVendorID;
        Paddle.sharedInstance.apiKey = myPaddleAPIKey;
        Paddle.sharedInstance.productID = myPaddleProductID;
    }

    Paddle.sharedInstance.canForceExit = false;
    
    PADProduct *paddleProduct = [[PADProduct alloc] initWithProductID:myPaddleProductID productType:PADProductTypeSDKProduct configuration:defaultProductConfig];
    
    // Required for Catlina
    if (MF_extra.sharedInstance.macOS >= 15)
        [paddleProduct verifyActivationWithCompletion:^(PADVerificationState state, NSError * _Nullable error) { }];
    
//    NSLog(@"%@ : %@ : %@", Paddle.sharedInstance.apiKey, Paddle.sharedInstance.vendorID, Paddle.sharedInstance.productID);
    
    return paddleProduct;
}

+ (void)purchasePlugin:(MF_Plugin*)plugin withButton:(NSButton*)theButton andProgress:(NSProgressIndicator*)progress {
    // Initialize the Product you'd like to work with:
    PADProduct *paddleProduct = [MF_Paddle productWithPlugin:plugin];

    [Paddle.sharedInstance showCheckoutForProduct:paddleProduct options:nil checkoutStatusCompletion:^(PADCheckoutState state, PADCheckoutData * _Nullable checkoutData) {
        // Examine checkout state to determine the checkout result
        if (state == PADCheckoutPurchased) {
            plugin.hasPurchased = true;
            [MSAnalytics trackEvent:@"Purchased Product" withProperties:@{@"Product" : plugin.webName, @"Product ID" : [plugin.webPlist valueForKey:@"productID"]}];
            [MF_Purchase pluginInstall:plugin withButton:theButton andProgress:progress];
            NSLog(@"Purchase success");
        } else {
            NSLog(@"Purchase canceled or failed.");
        }
    }];
}
    
+ (void)validadePlugin:(MF_Plugin*)plugin withButton:(NSButton*)theButton {
    // Initialize the Product
    PADProduct *paddleProduct = [MF_Paddle productWithPlugin:plugin];

    [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
        plugin.checkedPurchase = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([paddleProduct activated] || ([paddleProduct trialDaysRemaining] > 0)) {
                plugin.hasPurchased = true;
                plugin.paddleEmail = paddleProduct.activationEmail;
                plugin.paddleLicense = paddleProduct.licenseCode;
                // Trial mode
                if (![paddleProduct activated]) {
                    plugin.paddleEmail = @"Trial version";
                    plugin.paddleLicense = [NSString stringWithFormat:@"%@ days remaining", paddleProduct.trialDaysRemaining];
                }
                if ([MF_PluginManager.sharedInstance pluginLocalPath:plugin.bundleID].length)
                    theButton.title = @"OPEN";
                else
                    theButton.title = @"GET";
                NSLog(@"Verified... %@", plugin.bundleID);
            } else {
                plugin.hasPurchased = false;
                theButton.title = plugin.webPrice;
                NSLog(@"Not activated ... %@", plugin.bundleID);
            }
            theButton.toolTip = @"";
            theButton.enabled = true;
        });

    }];
}

@end
