//
//  bundlePage.m
//  MacPlus
//
//  Created by Wolfgang Baird on 3/24/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import WebKit;
@import EDStarRating;

#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"
#import "SYFlatButton.h"

#import "ZKSwizzle.h"

@interface bundlePage : NSView <EDStarRatingProtocol>

@property IBOutlet EDStarRating*    starRating;
@property IBOutlet NSTextField*     starScore;
@property IBOutlet NSTextField*     starReviews;

// Bundle Display
@property IBOutlet NSTextField*     bundleName;
@property IBOutlet NSTextField*     bundleDesc;
@property IBOutlet NSTextField*     bundleDescShort;
@property IBOutlet NSImageView*     bundleImage;
@property IBOutlet NSImageView*     bundlePreview1;
@property IBOutlet NSImageView*     bundlePreview2;
@property IBOutlet NSButton*        bundlePreviewNext;
@property IBOutlet NSButton*        bundlePreviewPrev;
@property IBOutlet NSButton*        bundleDev;

// Bundle Infobox
@property IBOutlet NSTextField*     bundleTarget;
@property IBOutlet NSTextField*     bundleDate;
@property IBOutlet NSTextField*     bundleVersion;
@property IBOutlet NSTextField*     bundlePrice;
@property IBOutlet NSTextField*     bundleSize;
@property IBOutlet NSTextField*     bundleID;
@property IBOutlet NSTextField*     bundleCompat;

// Bundle Buttons
@property IBOutlet SYFlatButton*    bundleInstall;
@property IBOutlet SYFlatButton*    bundleShare;
@property IBOutlet NSButton*        bundleDelete;
@property IBOutlet NSButton*        bundleContact;
@property IBOutlet NSButton*        bundleDonate;

// Bundle Webview
@property IBOutlet WebView*         bundleWebView;

@property NSArray*                  bundlePreviewImages;
@property NSMutableArray*           bundlePreviewImagesMute;
@property NSString*                 currentBundle;
@property NSInteger                 currentPreview;

@end

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

@interface NSObject (logProperties)
- (void) logProperties;
@end

#import <objc/runtime.h>

@implementation NSObject (logProperties)

- (void) logProperties {

    NSLog(@"----------------------------------------------- Properties for object %@", self);

    @autoreleasepool {
        unsigned int numberOfProperties = 0;
        objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
        for (NSUInteger i = 0; i < numberOfProperties; i++) {
            objc_property_t property = propertyArray[i];
            NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
            NSLog(@"Property %@ Value: %@", name, [self valueForKey:name]);
        }
        free(propertyArray);
    }
    NSLog(@"-----------------------------------------------");
}

@end

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

- (NSImage *)imageTintedWithColor:(NSColor *)tint :(NSImage*)img {
    NSImage *image = [img copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
        [image unlockFocus];
    }
    return image;
}

-(void)viewWillDraw {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    });
    
    // Reviews
    
    NSImage *star = [self imageTintedWithColor:NSColor.lightGrayColor :[NSImage imageNamed:@"star.png"]];
    NSImage *highlight = [self imageTintedWithColor:NSColor.lightGrayColor :[NSImage imageNamed:@"starhighlighted.png"]];
    
    float randomScore = ((float)rand() / RAND_MAX) * 5;
    float randomReviews = ((float)rand() / RAND_MAX) * 100;

    _starScore.stringValue = [NSString stringWithFormat:@"%.1f", randomScore];
    _starReviews.stringValue = [NSString stringWithFormat:@"%.0f ratings", randomReviews];

    _starRating.starImage = star;
    _starRating.starHighlightedImage = highlight;
    _starRating.maxRating = 5.0;
    _starRating.delegate = self;
    _starRating.horizontalMargin = 12;
    _starRating.editable=NO;
    _starRating.displayMode=EDStarRatingDisplayAccurate;
    _starRating.rating= randomScore;
    
    _bundleInstall.backgroundNormalColor = [NSColor colorWithRed:0.08 green:0.52 blue:1.0 alpha:1.0];
    _bundleInstall.backgroundHighlightColor = [NSColor colorWithRed:0.08 green:0.52 blue:1.0 alpha:1.0];
    _bundleInstall.backgroundDisabledColor = NSColor.grayColor;
    _bundleInstall.titleNormalColor = NSColor.whiteColor;
    _bundleInstall.titleHighlightColor = NSColor.grayColor;
    _bundleInstall.titleDisabledColor = NSColor.whiteColor;
    _bundleInstall.cornerRadius = _bundleInstall.frame.size.height/2;
    _bundleInstall.borderWidth = 0;
    _bundleInstall.momentary = true;
    
    _bundleShare.backgroundNormalColor = [NSColor colorWithRed:0.08 green:0.52 blue:1.0 alpha:1.0];
    _bundleShare.backgroundHighlightColor = [NSColor grayColor];
    _bundleShare.imageNormalColor = NSColor.whiteColor;
    _bundleShare.imageHighlightColor = NSColor.whiteColor;
    _bundleShare.cornerRadius = _bundleShare.frame.size.height/2;
    _bundleShare.borderWidth = 0;
    _bundleShare.momentary = true;
    
    [self setWantsLayer:YES];
    self.layer.masksToBounds = YES;
    
    NSArray *allPlugins;
    MSPlugin *plugin = [pluginData sharedInstance].currentPlugin;
    
    if (plugin != nil) {
        item = plugin.webPlist;
        repoPackages = plugin.webRepository; 
    } else {
        if (![repoPackages isEqualToString:@""]) {
            
            // Sometimes this is slow
            
            NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", repoPackages]];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
            allPlugins = [dict allValues];
            
            // Hmmm...
            
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
    
    if (![_currentBundle isEqualToString:newString]) {
        _currentBundle = newString;
        
        newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"description"]];
        [self.bundleDesc setAttributedStringValue:[[NSMutableAttributedString alloc] initWithString:newString]];
//        [[self.bundleDesc textStorage] setAttributedString:[[NSMutableAttributedString alloc] initWithString:newString]];
        [self systemDarkModeChange:nil];
        
        newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"descriptionShort"]];
        self.bundleDescShort.stringValue = newString;
        
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
        
//        [self.bundleInstall setBordered:0];
//        CGRect old = self.bundleContact.frame;
//        CGRect frm = CGRectMake(old.origin.x + 7, old.origin.y + 32, 86, 21);
//        [self.bundleInstall setFrame:frm];
//        [self.bundleInstall.layer setBackgroundColor:[NSColor colorWithRed:0.3 green:0.8 blue:0.4 alpha:1.0].CGColor];
//        [self.bundleInstall.layer setCornerRadius:4];
        
        //    NSDate *startTime = [NSDate date];
        
//        NSMutableDictionary *installedPlugins = [[NSMutableDictionary alloc] init];
//        NSMutableDictionary *plugins = [PluginManager.sharedInstance getInstalledPlugins];
//        for (NSString *key in plugins.allKeys) {
//            NSDictionary *itemDict = [plugins objectForKey:key];
//            [installedPlugins setObject:itemDict forKey:[itemDict objectForKey:@"bundleId"]];
//        }
        
        NSMutableDictionary *installedPlugins = [PluginManager.sharedInstance getInstalledPlugins];

        //    NSDate *methodFinish = [NSDate date];
        //    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
        //    NSLog(@"%@ execution time : %f Seconds", startTime, executionTime);
        
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
            //        NSString *price = [NSString stringWithFormat:@"%@", [item objectForKey:@"price"]];
            if ([[item objectForKey:@"payed"] boolValue]) {
                self.bundleInstall.title = @"Verifying...";
                [self verifyPurchased];
                [self.bundleInstall setAction:@selector(installOrPurchase)];
            } else {
                [self.bundleInstall setEnabled:true];
                self.bundleInstall.title = @"GET";
                [self.bundleInstall setAction:@selector(pluginInstall)];
            }
        }
        
        self.bundlePreview1.animates = YES;
        self.bundlePreview1.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        self.bundlePreview2.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        
        self.bundlePreview1.canDrawSubviewsIntoLayer = YES;
        _bundlePreviewImages = @[[[NSImage alloc] init], [[NSImage alloc] init]];
        
        NSString *bundle = [NSString stringWithFormat:@"%@", [self->item objectForKey:@"package"]];
        
        NSMutableArray *abc = [[NSMutableArray alloc] init];
        for (int i = 1; i <= 6; i++) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/0%u.png", repoPackages, bundle, i]];
            [abc addObject:url];
//            NSLog(@"%@", url.absoluteString);
        }
        
//        NSURL *url1 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/01.png", repoPackages, bundle]];
//        NSURL *url2 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/02.png", repoPackages, bundle]];
//        NSURL *url3 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/03.png", repoPackages, bundle]];
//        NSURL *url4 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/04.png", repoPackages, bundle]];
//        NSURL *url5 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/05.png", repoPackages, bundle]];
//        NSURL *url6 = [NSURL URLWithString:[NSString stringWithFormat:@"%@/images/%@/06.png", repoPackages, bundle]];
        
        _bundlePreviewImagesMute = [[NSMutableArray alloc] init];
        SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
        
        for (int i = 0; i < 6; i++) {
            NSURL *url = [abc objectAtIndex:i];
            
            [downloader downloadImageWithURL:url
            completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                if (image) {
                    [self->_bundlePreviewImagesMute addObject:image];
                    self->_bundlePreviewImages = self->_bundlePreviewImagesMute.copy;
                }
            }];
           
//            SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
//            [downloader downloadImageWithURL:url1
//                                   completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
//                                       if (image) {
//                                           [self->_bundlePreviewImagesMute addObject:image];
//                                           self->_bundlePreviewImages = self->_bundlePreviewImagesMute.copy;
//                                       }
//                                   }];
        }
        
        
        self.bundlePreview1.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        self.bundlePreview1.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        
        self.bundlePreview2.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        self.bundlePreview2.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        
        [self.bundlePreview1 sd_setImageWithURL:abc[0]
                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        [self.bundlePreview2 sd_setImageWithURL:abc[1]
                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
//        dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.w0lf.MacForge.0", 0);
//        dispatch_async(backgroundQueue0, ^{
//
//            NSData * data = [[NSData alloc] initWithContentsOfURL: abc[0]];
//            NSImage *preview1, *preview2;
//
//            if ( data == nil ) {
//                preview1 = [[NSImage alloc] init];
//                preview2 = [[NSImage alloc] init];
//            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                });
//            }
//        });
        
        
        
        self.bundleImage.image = [PluginManager pluginGetIcon:item];
        [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
    }
}

- (IBAction)shareMe:(id)sender {
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[[NSURL URLWithString:@"https://www.macenhance.com/"]]];
//    sharingServicePicker.delegate = [[NSSharingServicePicker alloc] delegate];
    [sharingServicePicker showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}

- (IBAction)cyclePreviews:(id)sender {
    NSLog(@"%lu", (unsigned long)_bundlePreviewImages.count);
    
    if (_bundlePreviewImages.count > 2) {
        NSInteger increment = -1;
        if ([sender isEqual:_bundlePreviewNext])
            increment = 1;
        
        NSInteger newPreview = _currentPreview += increment;
        if (increment == 1)
            if (newPreview >= _bundlePreviewImages.count)
                newPreview = 0;
        
        if (increment == -1)
            if (newPreview < 0)
                newPreview = _bundlePreviewImages.count - 1;
        
        _currentPreview = newPreview;
        self.bundlePreview1.image = self.bundlePreviewImages[newPreview];
        
        NSInteger secondPreview = newPreview + 1;
        if (secondPreview < _bundlePreviewImages.count)
            self.bundlePreview2.image = self.bundlePreviewImages[secondPreview];
        else
            self.bundlePreview2.image = self.bundlePreviewImages[0];
    }
}

- (void)verifyPurchased {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";

        NSDictionary *dict = [item objectForKey:@"paddle"];
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
               if ([task terminationStatus] == 69) {
                    NSLog(@"Verified...");
                    self.bundleInstall.title = @"GET";
                } else {
                    self.bundleInstall.title = self.bundlePrice.stringValue;
                }
           });
        });
    }
}

- (void)installOrPurchase {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSString *myPaddleProductID = [item objectForKey:@"productID"];
    if (myPaddleProductID != nil) {
        NSString *myPaddleVendorID = @"26643";
        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";

        NSDictionary *dict = [item objectForKey:@"paddle"];
        if (dict != nil) {
            myPaddleVendorID = [dict objectForKey:@"vendorid"];
            myPaddleAPIKey = [dict objectForKey:@"apikey"];
        }
    
        NSBundle *b = [NSBundle mainBundle];
        NSString *execPath = [b pathForResource:@"purchaseValidationApp" ofType:@"app"];
        execPath = [NSString stringWithFormat:@"%@/Contents/MacOS/purchaseValidationApp", execPath];
//        NSDictionary* test = [[NSDictionary alloc] initWithObjectsAndKeys:@"535218", @"productID", @"26643", @"vendorID", @"02a3c57238af53b3c465ef895729c765", @"APIKey", nil];
        
        NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[myPaddleProductID, myPaddleVendorID, myPaddleAPIKey]];
        // Testing
//        NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[@"520974", @"26643", @"02a3c57238af53b3c465ef895729c765"]];
//        NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[@"570933", @"102003", @"508205c7de527e9cc702cd1b1e5e2733"]];
        [task waitUntilExit];
//        NSLog(@"%d", task.terminationStatus);

        if ([task terminationStatus] == 69) {
            NSLog(@"Installing...");
            [self pluginInstall];
        } else {
            NSLog(@"Failed to purchase or validate purchase.");
        }
    }
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
        [PluginManager.sharedInstance readPlugins:nil];
        [self.bundleInstall setTitle:@"Open"];
        [self.bundleInstall setAction:@selector(pluginFinder)];
        [self.bundleDelete setEnabled:true];
        [self viewWillDraw];
    });
}

- (void)pluginFinder {
    [PluginManager.sharedInstance pluginRevealFinder:item];
}

- (void)pluginDelete {
    [PluginManager.sharedInstance pluginDelete:item];
    [PluginManager.sharedInstance readPlugins:nil];
    [self.bundleInstall setTitle:@"GET"];
    [self.bundleInstall setAction:@selector(installOrPurchase)];
    [self.bundleDelete setEnabled:false];
    [self viewWillDraw];
}

@end
