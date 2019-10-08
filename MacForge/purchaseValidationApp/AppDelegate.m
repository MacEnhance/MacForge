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

- (NSString *)customStoragePath {
    [self updateToShared];
    return paddleFldr; //Needs to be full path to custom storage directory
}

- (void)updateToShared {
    if (![FileManager fileExistsAtPath:paddleFldr]) {
        NSError *err;
        [FileManager createDirectoryAtPath:paddleFldr withIntermediateDirectories:true attributes:nil error:&err];
        [self updatePaddleData];
    } else {
        NSString *updFile = [paddleFldr stringByAppendingPathComponent:@"com.macenhance.purchaseValidationApp"];
        if (![FileManager fileExistsAtPath:updFile]) {
            [FileManager createFileAtPath:updFile contents:nil attributes:nil];
            [self updatePaddleData];
        }
    }
}

- (void)updatePaddleData {
    // Make sure public folder exists
    NSError *err;
    [FileManager createDirectoryAtPath:paddleFldr withIntermediateDirectories:true attributes:nil error:&err];
    
    NSString *oldFolder = [NSString stringWithFormat:@"%@/purchaseValidationApp", appSupport];
    NSArray *paddleFiles = [FileManager contentsOfDirectoryAtPath:oldFolder error:nil];
        
    for (NSString *file in paddleFiles) {
        // Remove old files
        NSString *publicFile = [paddleFldr stringByAppendingPathComponent:file];
        NSString *userFile = [NSString stringWithFormat:@"%@/purchaseValidationApp/%@", appSupport, file];
        if ([FileManager fileExistsAtPath:publicFile]) {
            [FileManager removeItemAtPath:publicFile error:&err];
            //        DLog(@"Removed public paddata %@", err);
        }
        if ([FileManager fileExistsAtPath:userFile]) {
            [FileManager copyItemAtPath:userFile toPath:publicFile error:&err];
            //        DLog(@"Inserted paddata %@", err);
        }
    }
}

- (void)didDismissPaddleUIType:(PADUIType)uiType triggeredUIType:(PADTriggeredUIType)triggeredUIType product:(nonnull PADProduct *)product {
//    NSLog(@"%ld : %ld : %@", (long)uiType, (long)triggeredUIType, product);
    
    switch (triggeredUIType) {
        case PADTriggeredUITypeCancel:
            // Quit pressed
            exit(1337);
            break;
        case PADTriggeredUITypeContinueTrial:
            //Continue trial pressed
            exit(69);
            break;
        default:
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
    
    // Required for Catlina
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 15)
        [paddleProduct verifyActivationWithCompletion:^(PADVerificationState state, NSError * _Nullable error) { }];
    
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
