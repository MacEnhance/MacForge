//
//  bundlePage.m
//  mySIMBL
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
extern NSMutableArray *pluginsArray;
extern long selectedRow;

@implementation bundlePage {
    bool doOnce;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
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
//        if (strSize.width > targetWidth) break;
    }
    NSFont *result = [NSFont fontWithName:currentFontName size:i-1];
    return result;
}

-(void)viewWillDraw {
    [self setWantsLayer:YES];
    self.layer.masksToBounds = YES;
//    self.layer.borderWidth = 1.0f;
//    [self.layer setBorderColor:[NSColor grayColor].CGColor];
    
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
        {
            doOnce = true;
//            [[[[[self.bundleWebView mainFrame] frameView] documentView] superview] scaleUnitSquareToSize:NSMakeSize(.5, .5)];
//            [[[[[self.bundleWebView mainFrame] frameView] documentView] superview] setNeedsDisplay:YES];
        }
//        NSURL*url=[NSURL URLWithString:@"http://w0lfschild.github.io/app_cDock"];
        NSURL*url=[NSURL URLWithString:[item objectForKey:@"webpage"]];
        NSURLRequest*request=[NSURLRequest requestWithURL:url];
        [[self.bundleWebView mainFrame] loadRequest:request];
    } else {
//        NSURL*url=[NSURL URLWithString:@"http://w0lfschild.github.io/app_cDock"];
//        NSURLRequest*request=[NSURLRequest requestWithURL:url];
//        [[self.bundleWebView mainFrame] loadRequest:request];
        [[self.bundleWebView mainFrame] loadHTMLString:nil baseURL:nil];
    }
    
    installedPlugins = [[NSMutableDictionary alloc] init];
    for (NSDictionary* dict in pluginsArray) {
        NSString* str = [dict objectForKey:@"bundleId"];
        [installedPlugins setObject:dict forKey:str];
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
            [self.bundleInstall setAction:@selector(pluginUpdate)];
        } else {
            //versionA > versionB
            [self.bundleInstall setEnabled:false];
            self.bundleInstall.title = @"Downgrade";
            [self.bundleInstall setAction:@selector(pluginUpdate)];
        }
    } else {
        // Package not installed
        [self.bundleInstall setEnabled:true];
        self.bundleInstall.title = @"Get";
        [self.bundleInstall setAction:@selector(pluginInstall)];
    }
    
    self.bundleImage.image = [PluginManager pluginGetIcon:item];
    [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
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
//            [myDelegate pushView:nil];
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
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repoPackages, [item objectForKey:@"filename"]]];
    NSData *myData = [NSData dataWithContentsOfURL:installURL];
    NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
    [myData writeToFile:temp atomically:YES];
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", libPathENB]];
    [task waitUntilExit];
    [self.bundleDelete setEnabled:true];
    [self.bundleInstall setEnabled:true];
    self.bundleInstall.title = @"Open";
    [self.bundleInstall setAction:@selector(pluginFinder)];
    [PluginManager.sharedInstance readPlugins:nil];
}

- (void)pluginUpdate {
    NSURL *installURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", repoPackages, [item objectForKey:@"filename"]]];
    NSData *myData = [NSData dataWithContentsOfURL:installURL];
    NSString *temp = [NSString stringWithFormat:@"/tmp/%@_%@", [item objectForKey:@"package"], [item objectForKey:@"version"]];
    [myData writeToFile:temp atomically:YES];
    NSArray* libDomain = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSLocalDomainMask];
    NSString* libSupport = [[libDomain objectAtIndex:0] path];
    NSString* libPathENB = [NSString stringWithFormat:@"%@/SIMBL/Plugins", libSupport];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", temp, @"-d", libPathENB]];
    [task waitUntilExit];
    [self.bundleDelete setEnabled:true];
    [self.bundleInstall setEnabled:true];
    self.bundleInstall.title = @"Open";
    [self.bundleInstall setAction:@selector(pluginFinder)];
    [PluginManager.sharedInstance readPlugins:nil];
}

- (void)pluginFinder {
    int pos = 0;
    bool found = false;
    for (NSDictionary* dict in pluginsArray) {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:[item objectForKey:@"package"]]) {
            found = true;
            break;
        }
        pos += 1;
    }
    
    if (found) {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
    }
}

- (void)pluginDelete {
    int pos = 0;
    bool found = false;
    for (NSDictionary* dict in pluginsArray) {
        if ([[dict objectForKey:@"bundleId"] isEqualToString:[item objectForKey:@"package"]]) {
            found = true;
            break;
        }
        pos += 1;
    }
    
    if (found) {
        NSDictionary* obj = [pluginsArray objectAtIndex:pos];
        NSString* path = [obj objectForKey:@"path"];
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
    
    [self.bundleDelete setEnabled:false];
    [self.bundleInstall setEnabled:true];
    self.bundleInstall.title = @"Install";
    [self.bundleInstall setAction:@selector(pluginInstall)];
}

@end
