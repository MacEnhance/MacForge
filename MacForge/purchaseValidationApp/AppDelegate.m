//
//  AppDelegate.m
//  purchaseValidationApp
//
//  Created by Wolfgang Baird on 9/20/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)didDismissPaddleUIType:(PADUIType)uiType triggeredUIType:(PADTriggeredUIType)triggeredUIType product:(nonnull PADProduct *)product {
    NSLog(@"%ld : %ld : %@", (long)uiType, (long)triggeredUIType, product);
    
    if (triggeredUIType == 6) {
        // Quit pressed
        exit(1337);
    } else {
        [self checkEm:product];
    }
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    //    NSLog(@"%@", arguments);
        
    //    NSDictionary *test = [[NSDictionary alloc] initWithObjectsAndKeys:@"570933", @"productID", @"102003", @"vendorID", @"508205c7de527e9cc702cd1b1e5e2733", @"APIKey", nil];
    NSDictionary *test = [[NSDictionary alloc] initWithObjectsAndKeys:@"534403", @"productID", @"26643", @"vendorID", @"02a3c57238af53b3c465ef895729c765", @"APIKey", nil];
    if (![arguments containsObject:@"-NSDocumentRevisionsDebugMode"])
        test = [[NSDictionary alloc] initWithObjectsAndKeys:arguments[1], @"productID", arguments[2], @"vendorID", arguments[3], @"APIKey", nil];
    
    if ([arguments containsObject:@"-v"]) {
        [self checkAndReturn:test];
    } else {
        [self purchased:test];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (PADProduct*)setupPaddle:(NSDictionary *)paddleProductDict {
    NSString *myPaddleProductID = [paddleProductDict valueForKey:@"productID"];
    NSString *myPaddleVendorID = [paddleProductDict valueForKey:@"vendorID"];
    NSString *myPaddleAPIKey = [paddleProductDict valueForKey:@"APIKey"];
    
    // Populate a local object in case we're unable to retrieve data from the Vendor Dashboard:
    PADProductConfiguration *defaultProductConfig = [[PADProductConfiguration alloc] init];
    defaultProductConfig.productName = @"plugin";
    defaultProductConfig.vendorName = @"macenhance";
    
    [Paddle sharedInstanceWithVendorID:myPaddleVendorID
                                apiKey:myPaddleAPIKey
                             productID:myPaddleProductID
                         configuration:defaultProductConfig
                              delegate:self];
    
    // Initialize the Product you'd like to work with:
    PADProduct *paddleProduct = [[PADProduct alloc] initWithProductID:myPaddleProductID productType:PADProductTypeSDKProduct configuration:defaultProductConfig];
    return paddleProduct;
}

- (void)purchased:(NSDictionary *)paddleProductDict {
    // Bring app to front
    [NSApp activateIgnoringOtherApps:YES];
    
    // Setup paddle
    PADProduct *paddleProduct = [self setupPaddle:paddleProductDict];
    
    // Show purchase UI if product not already purchased
    [self showPurchaseUI:paddleProduct];
}

- (void)showPurchaseUI:(PADProduct *)paddleProduct {
    [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
        if ([paddleProduct activated]) {
            NSLog(@"install");
            exit(69);
        } else {
            [Paddle.sharedInstance showCheckoutForProduct:paddleProduct options:nil checkoutStatusCompletion:^(PADCheckoutState state, PADCheckoutData * _Nullable checkoutData) {
                // Examine checkout state to determine the checkout result
                if (state == PADCheckoutPurchased) {
                    NSLog(@"install");
                    exit(69);
                }
            }];
        }
    }];
}

- (void)checkEm:(PADProduct *)paddleProduct {
    [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
        if ([paddleProduct activated]) {
            NSLog(@"install");
            exit(69);
        }
    }];
}

- (void)checkAndReturn:(NSDictionary *)paddleProductDict {
    // Setup paddle
    PADProduct *paddleProduct = [self setupPaddle:paddleProductDict];
    
    // Check product
    [paddleProduct refresh:^(NSDictionary * _Nullable productDelta, NSError * _Nullable error) {
        if ([paddleProduct activated]) {
            NSLog(@"Verfied activation");
            exit(69);
        } else {
            NSLog(@"Not activated");
            exit(1337);
        }
    }];
}

@end
