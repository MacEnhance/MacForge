//
//  bundlePage.m
//  MacPlus
//
//  Created by Wolfgang Baird on 3/24/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import WebKit;
#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"

@interface bundlePage : NSView

// Bundle Display
@property IBOutlet NSTextField*     bundleName;
@property IBOutlet NSTextView*      bundleDesc;
@property IBOutlet NSImageView*     bundleImage;

// Bundle Infobox
@property IBOutlet NSTextField*     bundleTarget;
@property IBOutlet NSTextField*     bundleDate;
@property IBOutlet NSTextField*     bundleVersion;
@property IBOutlet NSTextField*     bundlePrice;
@property IBOutlet NSTextField*     bundleSize;
@property IBOutlet NSTextField*     bundleID;
@property IBOutlet NSTextField*     bundleDev;
@property IBOutlet NSTextField*     bundleCompat;

// Bundle Buttons
@property IBOutlet NSButton*        bundleInstall;
@property IBOutlet NSButton*        bundleDelete;
@property IBOutlet NSButton*        bundleContact;
@property IBOutlet NSButton*        bundleDonate;

// Bundle Webview
@property IBOutlet WebView*         bundleWebView;

@end

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

@implementation bundlePage {
    bool doOnce;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
}

- (void)systemDarkModeChange:(NSNotification *)notif {
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        [_bundleDesc setTextColor:[NSColor whiteColor]];
    } else {
        [_bundleDesc setTextColor:[NSColor blackColor]];
    }
}

-(NSFont*)calcFontSizeToFitRect:(NSRect)r :(NSString*)string :(NSString*)currentFontName {
    float targetWidth = r.size.width - 4;
    float targetHeight = r.size.height;
    
    // the strategy is to start with a small font size and go larger until I'm larger than one of the target sizes
    int i;
    for (i=1; i<36; i++) {
        NSDictionary* attrs = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:currentFontName size:i], NSFontAttributeName, nil];
        NSSize strSize = [string sizeWithAttributes:attrs];
        if (strSize.width > targetWidth || strSize.height > targetHeight) break;
    }
    NSFont *result = [NSFont fontWithName:currentFontName size:i-1];
    return result;
}

-(void)viewWillDraw {
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    
    [self setWantsLayer:YES];
    self.layer.masksToBounds = YES;
    
    NSArray *allPlugins;
    MSPlugin *plugin = [pluginData sharedInstance].currentPlugin;
    
    if (plugin != nil) {
        item = plugin.webPlist;
        repoPackages = plugin.webRepository;
    } else {
        if (![repoPackages isEqualToString:@""]) {
            NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", repoPackages]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
            allPlugins = [dict allValues];
            
            NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
            NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
            NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
            allPlugins = sortedArray;
        } else {
            NSMutableArray *sourceURLS = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"]];
            NSMutableDictionary *comboDic = [[NSMutableDictionary alloc] init];
            for (NSString *url in sourceURLS) {
                NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", url]];
                NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
                [comboDic addEntriesFromDictionary:sourceDic];
            }
            allPlugins = [comboDic allValues];
        }
        item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:selectedRow]];
    }
    
    NSString* newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"name"]];
    [self.bundleName setFont:[self calcFontSizeToFitRect:self.bundleName.frame :newString :self.bundleName.font.fontName]];
    self.bundleName.stringValue = newString;
    
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"description"]];
    [[self.bundleDesc textStorage] setAttributedString:[[NSMutableAttributedString alloc] initWithString:newString]];
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"]) {
        [_bundleDesc setTextColor:[NSColor whiteColor]];
    } else {
        [_bundleDesc setTextColor:[NSColor blackColor]];
    }
    
    //Target
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"apps"]];
    self.bundleTarget.stringValue = newString;
    
    //Date
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"date"]];
    self.bundleDate.stringValue = newString;
    
    //Version
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"version"]];
    self.bundleVersion.stringValue = newString;
    
    //Price
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"price"]];
    self.bundlePrice.stringValue = newString;
    
    //Size
    long long bundlesize = [[item objectForKey:@"size"] integerValue];
    self.bundleSize.stringValue = [NSByteCountFormatter stringFromByteCount:bundlesize countStyle:NSByteCountFormatterCountStyleFile];
    
    //Bundle
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"package"]];
    [self.bundleID setFont:[self calcFontSizeToFitRect:self.bundleID.frame :newString :self.bundleID.font.fontName]];
    self.bundleID.stringValue = newString;
    
    //Developer
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"author"]];
    self.bundleDev.stringValue = newString;
    
    //Compatibility
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"compat"]];
    self.bundleCompat.stringValue = newString;
    
    if ([[item objectForKey:@"webpage"] length]) {
        if (!doOnce)
            doOnce = true;
        NSURL*url=[NSURL URLWithString:[item objectForKey:@"webpage"]];
        NSURLRequest*request=[NSURLRequest requestWithURL:url];
        [[self.bundleWebView mainFrame] loadRequest:request];
    } else {
        [[self.bundleWebView mainFrame] loadHTMLString:nil baseURL:nil];
    }
    
    if (![[item objectForKey:@"donate"] length])
        [self.bundleDonate setEnabled:false];
    else
        [self.bundleDonate setEnabled:true];
    
    if (![[item objectForKey:@"contact"] length])
        [self.bundleContact setEnabled:false];
    else
        [self.bundleContact setEnabled:true];
    
    [self.bundleContact setTarget:self];
    [self.bundleDonate setTarget:self];
    
    [self.bundleContact setAction:@selector(contactDev)];
    [self.bundleDonate setAction:@selector(donateDev)];
    
    [self.bundleInstall setTarget:self];
    [self.bundleDelete setTarget:self];
    [self.bundleDelete setAction:@selector(pluginDelete)];
    
    NSMutableDictionary *installedPlugins = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *plugins = [PluginManager.sharedInstance getInstalledPlugins];
    for (NSString *key in plugins.allKeys) {
        NSDictionary *itemDict = [plugins objectForKey:key];
        [installedPlugins setObject:itemDict forKey:[itemDict objectForKey:@"bundleId"]];
    }
    
    if ([installedPlugins objectForKey:[item objectForKey:@"package"]]) {
        // Pack already exists
        [self.bundleDelete setEnabled:true];
        NSDictionary* dic = [[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"];
        NSString* cur = [dic objectForKey:@"CFBundleShortVersionString"];
        if ([cur isEqualToString:@""])
            cur = [dic objectForKey:@"CFBundleVersion"];
        NSString* new = [item objectForKey:@"version"];
        id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
        NSInteger result = [comparator compareVersion:cur toVersion:new];
        if (result == NSOrderedSame) {
            //versionA == versionB
            [self.bundleInstall setEnabled:true];
            self.bundleInstall.title = @"Open";
            [self.bundleInstall setAction:@selector(pluginFinder)];
        } else if (result == NSOrderedAscending) {
            //versionA < versionB
            [self.bundleInstall setEnabled:true];
            self.bundleInstall.title = @"Update";
            [self.bundleInstall setAction:@selector(pluginInstall)];
        } else {
            //versionA > versionB
            [self.bundleInstall setEnabled:false];
            self.bundleInstall.title = @"Downgrade";
            [self.bundleInstall setAction:@selector(pluginInstall)];
        }
    } else {
        // Package not installed
        [self.bundleDelete setEnabled:false];
        NSString *price = [NSString stringWithFormat:@"%@", [item objectForKey:@"price"]];
        if ([[item objectForKey:@"isPaid"] boolValue]) {
            self.bundleInstall.title = @"";
            [self verifyPurchased];
            [self.bundleInstall setAction:@selector(testmethod)];
        } else {
            [self.bundleInstall setEnabled:true];
            self.bundleInstall.title = @"Install";
            [self.bundleInstall setAction:@selector(pluginInstall)];
        }
    }
    
    self.bundleImage.image = [PluginManager pluginGetIcon:item];
    [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
}

- (void)verifyPurchased {
    if ([item objectForKey:@"productInfo"]) {
        NSDictionary *productWebInfo =[item objectForKey:@"productInfo"];
        NSString *productID = [productWebInfo objectForKey:@"productID"];
        NSString *vendorID = [productWebInfo objectForKey:@"vendorID"];
        NSString *apiKey = [productWebInfo objectForKey:@"apiKey"];
        Paddle *thePaddle = [Paddle sharedInstance];
        [thePaddle setProductId:productID];
        [thePaddle setVendorId:vendorID];
        [thePaddle setApiKey:apiKey];
        NSDictionary *productInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"0.99", kPADCurrentPrice,
                                     @"Wolfgang Baird", kPADDevName,
                                     @"USD", kPADCurrency,
                                     @"https://dl.devmate.com/org.w0lf.cDock-GUI/icons/5aae1388a46dd_128.png", kPADImage,
                                     @"testProduct", kPADProductName,
                                     @"0", kPADTrialDuration,
                                     @"Thanks for purchasing", kPADTrialText,
                                     @"icon.icns", kPADProductImage,
                                     nil];
        [thePaddle setupChildProduct:productID productInfo:productInfo timeTrial:NO];
        [thePaddle verifyLicenceForChildProduct:productID withCompletionBlock:^(BOOL purchased, NSError *e) {
//            NSLog(@"Purchased %@ : %hhd", [self->item objectForKey:@"package"], purchased);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (purchased) {
                    self.bundleInstall.title = @"Install";
                } else {
                    self.bundleInstall.title = @"$1.99";
                }
            });
        }];
    } else {
        NSLog(@"No product info ???");
    }
}

- (void)testmethod {
    NSLog(@"purchaseAndInstall");
    NSString *productID = [[item objectForKey:@"productInfo"] objectForKey:@"productID"];
    NSString *vendorID = [[item objectForKey:@"productInfo"] objectForKey:@"vendorID"];
    NSString *apiKey = [[item objectForKey:@"productInfo"] objectForKey:@"apiKey"];
    Paddle *thePaddle = [Paddle sharedInstance];
    [thePaddle setProductId:productID];
    [thePaddle setVendorId:vendorID];
    [thePaddle setApiKey:apiKey];
    NSDictionary *productInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"1.99", kPADCurrentPrice,
                                 @"Wolfgang Baird", kPADDevName,
                                 @"USD", kPADCurrency,
                                 @"https://dl.devmate.com/org.w0lf.cDock-GUI/icons/5aae1388a46dd_128.png", kPADImage,
                                 @"moreMenu", kPADProductName,
                                 @"0", kPADTrialDuration,
                                 @"Thanks for purchasing", kPADTrialText,
                                 @"icon.icns", kPADProductImage,
                                 nil];
    [thePaddle setupChildProduct:productID productInfo:productInfo timeTrial:NO];
    [thePaddle verifyLicenceForChildProduct:productID withCompletionBlock:^(BOOL purchased, NSError *e) {
//        NSLog(@"Purchased : %hhd - Error : %@", purchased, e.localizedDescription);
        if (purchased) {
            [self pluginInstall];
        } else {
            [thePaddle startPurchaseForChildProduct:productID];
        }
    }];
}

- (void)keyDown:(NSEvent *)theEvent {
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    bool                specKey     =   false;
    switch (code)
    {
        case NSLeftArrowFunctionKey:
        {
            [myDelegate popView:nil];
            specKey = true;
            break;
        }
        case NSRightArrowFunctionKey:
        {
            [myDelegate pushView:nil];
            specKey = true;
            break;
        }
        case NSCarriageReturnCharacter:
        {
            [self.bundleInstall performClick:nil];
            specKey = true;
            break;
        }
    }
    
    if (!specKey)
        [super keyDown:theEvent];
}

- (void)contactDev {
    NSURL *mailtoURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [item objectForKey:@"contact"]]];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

- (void)donateDev {
     [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[item objectForKey:@"donate"]]];
}

- (void)pluginInstall {
    [PluginManager.sharedInstance pluginUpdateOrInstall:item :repoPackages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.bundleDelete setEnabled:true];
        [self viewWillDraw];
    });
}

- (void)pluginFinder {
    [PluginManager.sharedInstance pluginRevealFinder:item];
}

- (void)pluginDelete {
    [PluginManager.sharedInstance pluginDelete:item];
    [self.bundleDelete setEnabled:false];
    [self viewWillDraw];
}

@end
