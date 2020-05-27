//
//  MF_bundleView.m
//  MacForge
//
//  Created by Wolfgang Baird on 9/29/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_bundleView.h"

extern AppDelegate* myDelegate;
NSDictionary *testing;

@implementation MF_bundleView {
    bool doOnce;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
}

- (void)systemDarkModeChange:(NSNotification *)notif {
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 14) {
        NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
        if ([osxMode isEqualToString:@"Dark"]) {
            [_bundleDesc setTextColor:[NSColor whiteColor]];
        } else {
            [_bundleDesc setTextColor:[NSColor blackColor]];
        }
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
        NSRectFillUsingOperation(imageRect, NSCompositingOperationSourceAtop);
        [image unlockFocus];
    }
    return image;
}

-(void)viewWillDraw {
    self.bundlePreviewAVPlayer.hidden = true;
    
    for (NSView* v in self.subviews)
        if ([v.className isEqualToString:@"MF_bundlePreviewView"])
            [v removeFromSuperview];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    });
    
    // Reviews
    _starScore.hidden = true;
    _starRating.hidden = true;
    _starReviews.hidden = true;
    
    NSImage *star = [self imageTintedWithColor:NSColor.lightGrayColor :[NSImage imageNamed:@"star.png"]];
    NSImage *highlight = [self imageTintedWithColor:NSColor.lightGrayColor :[NSImage imageNamed:@"starhighlighted.png"]];
    
    float randomScore = ((float)rand() / RAND_MAX) * 5;
    float randomReviews = ((float)rand() / RAND_MAX) * 100;

    _starScore.stringValue = [NSString stringWithFormat:@"%.1f", randomScore];
    _starReviews.stringValue = [NSString stringWithFormat:@"%.0f ratings", randomReviews];
    
    if (!testing) {
//        if (reviewsDict.data[@"ratings"]) {
            NSDictionary *rate = testing[@"ratings"];
            float total = 0;
            for (NSString *key in rate.allKeys)
                total += [[rate valueForKey:key] floatValue];
            total /= rate.allKeys.count;

//            _starScore.stringValue = [NSString stringWithFormat:@"%.1f", total];
//            _starReviews.stringValue = [NSString stringWithFormat:@"%.0lu ratings", (unsigned long)rate.allKeys.count];

            _starRating.starImage = star;
            _starRating.starHighlightedImage = highlight;
            _starRating.maxRating = 5.0;
            _starRating.delegate = self;
            _starRating.horizontalMargin = 12;
            _starRating.editable = NO;
            _starRating.displayMode = EDStarRatingDisplayAccurate;
            _starRating.rating = randomScore;

            _starScore.hidden = false;
            _starRating.hidden = false;
            _starReviews.hidden = false;
//        }
    } else {
        _starScore.stringValue = @"0.0";
        _starReviews.stringValue = @"Not Enough Ratings";
        [_starRating setFrameOrigin:_starScore.frame.origin];
        _starRating.starImage = star;
        _starRating.starHighlightedImage = highlight;
        _starRating.maxRating = 5.0;
        _starRating.delegate = self;
        _starRating.horizontalMargin = 12;
        _starRating.editable=NO;
        _starRating.displayMode=EDStarRatingDisplayAccurate;
        _starRating.rating= 0.0;
        _starRating.hidden = false;
        _starReviews.hidden = false;
    }
    
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
    
//    NSArray *allPlugins;
    MF_Plugin *plugin = [MF_repoData sharedInstance].currentPlugin;
    
    if (plugin != nil) {
        item = plugin.webPlist;
    } else {
//        if (![repoPackages isEqualToString:@""]) {
//            
//            // Sometimes this is slow
//            
//            NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages.plist", repoPackages]];
//            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
//            allPlugins = [dict allValues];
//            
//            // Hmmm...
//            
//            NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
//            NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
//            NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
//            allPlugins = sortedArray;
//        } else {
//            NSMutableArray *sourceURLS = [[NSMutableArray alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] objectForKey:@"sources"]];
//            NSMutableDictionary *comboDic = [[NSMutableDictionary alloc] init];
//            for (NSString *url in sourceURLS) {
//                NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages.plist", url]];
//                NSMutableDictionary *sourceDic = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
//                [comboDic addEntriesFromDictionary:sourceDic];
//            }
//            allPlugins = [comboDic allValues];
//        }
//        item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:selectedRow]];
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
//        self.bundleDev.stringValue = newString;
        _bundleDev.title = newString;
        _bundleSeller.stringValue = newString;
        _bundleCopyright.stringValue = [@"© 2019 " stringByAppendingString:newString];
        
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
        
        NSMutableDictionary *installedPlugins = [MF_PluginManager.sharedInstance getInstalledPlugins];

        //    NSDate *methodFinish = [NSDate date];
        //    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
        //    NSLog(@"%@ execution time : %f Seconds", startTime, executionTime);
        
//        Boolean installed = false;
        Boolean isApp = false;
        NSString *bundleID = [item objectForKey:@"package"];
        if ([Workspace URLForApplicationWithBundleIdentifier:bundleID]) isApp = true;
//        if ([installedPlugins objectForKey:bundleID])
//            installed = true;

//        if ([Workspace URLForApplicationWithBundleIdentifier:bundleID]) {
//            isApp = true;
//            if ([[Workspace URLForApplicationWithBundleIdentifier:bundleID].path.pathComponents.firstObject isEqualToString:@"/Applications"])
//                installed = true;
//        }
           
        if ([MF_PluginManager.sharedInstance pluginLocalPath:bundleID].length) {
//        if ([installedPlugins objectForKey:[item objectForKey:@"package"]]) {
            // Pack already exists
            [self.bundleDelete setEnabled:true];
            
            NSDictionary* dic = [[installedPlugins objectForKey:[item objectForKey:@"package"]] objectForKey:@"bundleInfo"];
            NSString* cur = [dic objectForKey:@"CFBundleShortVersionString"];
            if ([cur isEqualToString:@""])
               cur = [dic objectForKey:@"CFBundleVersion"];
            
            if (isApp) {
                NSURL *url = [Workspace URLForApplicationWithBundleIdentifier:bundleID];
                NSBundle *b = [NSBundle bundleWithURL:url];
                NSDictionary *d = [b infoDictionary];
                cur = [d valueForKey:@"CFBundleShortVersionString"];
            }
                        
            NSString* new = [item objectForKey:@"version"];
            id <SUVersionComparison> comparator = [SUStandardVersionComparator defaultComparator];
            NSInteger result = [comparator compareVersion:cur toVersion:new];
            
            NSLog(@"----------  %@ : %@", cur, new);

            
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
                self.bundleInstall.enabled = false;
                [self verifyPurchased];
                [self.bundleInstall setAction:@selector(installOrPurchase)];
            } else {
                [self.bundleInstall setEnabled:true];
                self.bundleInstall.title = @"GET";
                [self.bundleInstall setAction:@selector(pluginInstall)];
            }
        }
        
        self.bundlePreview1.animates = YES;
        self.bundlePreview1.canDrawSubviewsIntoLayer = YES;
        self.bundlePreview1.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        self.bundlePreview2.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        
        _bundlePreviewImages = @[[[NSImage alloc] init], [[NSImage alloc] init]];
        NSString *bundle = [NSString stringWithFormat:@"%@", [self->item objectForKey:@"package"]];
        
        _currentPreview = 0;
        NSMutableArray *abc = [[NSMutableArray alloc] init];
        for (int i = 1; i <= 6; i++) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/previewImages/0%u.png", @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo", bundle, i]];
            [abc addObject:url];
        }
        
        _bundlePreviewImagesMute = [[NSMutableArray alloc] init];
        SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
        
        [self.bundlePreviewButton1 setEnabled:false];
        [self.bundlePreviewButton2 setEnabled:false];

        for (int i = 0; i < 6; i++) {
            NSURL *url = [abc objectAtIndex:i];
            
            [downloader downloadImageWithURL:url
            completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                if (image) {
                    while (self.bundlePreviewImagesMute.count < i)
                        [self.bundlePreviewImagesMute addObject:[[NSImage alloc] init]];
                    
                    [self.bundlePreviewImagesMute setObject:image atIndexedSubscript:i];
                    self.bundlePreviewImages = self.bundlePreviewImagesMute.copy;
                    
                    if (!self.bundlePreviewButton1.enabled) {
                        [self.bundlePreviewButton1 setEnabled:true];
                        [self.bundlePreviewButton2 setEnabled:true];
                    }
                }
            }];
        }
        
//        [self.bundlePreviewAVPlayer.contentOverlayView setSubviews:@[self.bundlePreviewButton1]];
//        [self.bundlePreviewButton1 setFrameOrigin:CGPointMake(0, 0)];
//        [self.bundlePreviewButton1 setFrameSize:self.bundlePreviewAVPlayer.contentOverlayView.frame.size];
//        [self.bundlePreviewAVPlayer.layer setBackgroundColor:NSColor.clearColor.CGColor];
//        self.bundlePreviewAVPlayer.controlsStyle = AVPlayerViewControlsStyleNone;
//        self.bundlePreviewButton1.hidden = true;
//        self.bundlePreviewAVPlayer.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:@"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"]];
//        self.bundlePreviewAVPlayer.controlsStyle = AVPlayerViewControlsStyleInline;
//        if (@available(macOS 10.15, *)) {
//            self.bundlePreviewAVPlayer.allowsPictureInPicturePlayback = true;
//        } else {
//            // Fallback on earlier versions
//        }
//        [self.bundlePreviewAVPlayer.player play];
        
        [self.bundlePreviewButton1 setAction:@selector(pluginShowImages:)];
        [self.bundlePreviewButton1 setTarget:self];
        
        [self.bundlePreviewButton2 setAction:@selector(pluginShowImages:)];
        [self.bundlePreviewButton2 setTarget:self];
        
        self.bundlePreview1.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        self.bundlePreview1.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        
        self.bundlePreview2.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        self.bundlePreview2.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        
        [self.bundlePreviewButton1 sd_setImageWithURL:abc[0]
                                     placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        [self.bundlePreview1 sd_setImageWithURL:abc[0]
                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        self.bundlePreview1.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
        self.bundlePreview1.layer.cornerRadius = 5;
        
        
        [self.bundlePreview2 sd_setImageWithURL:abc[1]
                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        self.bundlePreview2.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
        self.bundlePreview2.layer.cornerRadius = 5;
        
//        self.bundlePreview1.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
//        self.bundlePreview1.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
//
//        self.bundlePreview2.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
//        self.bundlePreview2.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
//
//        [self.bundlePreview1 sd_setImageWithURL:abc[0]
//                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
//
//        [self.bundlePreview2 sd_setImageWithURL:abc[1]
//                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
        NSString *imgurl = [NSString stringWithFormat:@"%@%@", plugin.webRepository, iconpath];
                    
        if (iconpath) {
            self.bundleImage.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
            self.bundleImage.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
            [self.bundleImage sd_setImageWithURL:[NSURL URLWithString:imgurl]
                                 placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
        } else {
            NSImage *icon = [MF_PluginManager pluginGetIcon:plugin.webPlist];
            self.bundleImage.image = icon;
        }
        
//        self.bundleImage.image = [PluginManager pluginGetIcon:item];
        [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        
        
        // Resize views
        Boolean hasDescription = true;
        if ([[item objectForKey:@"description"] isEqualTo:[item objectForKey:@"descriptionShort"]])
            hasDescription = false;
        if (![item objectForKey:@"description"])
            hasDescription = false;
        
        NSRect prev = _viewPreviews.frame;
        prev.size.height = self.bundlePreview1.frame.size.width / 1.6 + 40;
        [_viewPreviews setFrame:prev];
        
        NSUInteger diff = 10;
        NSUInteger newDescHeight = 0;
        diff += _viewHeader.frame.size.height;
        if ([item objectForKey:@"hasPreview"]) { diff += _viewPreviews.frame.size.height; }
        if (hasDescription) {
            NSRect frame = [_bundleDesc frame];
            frame.size.height = CGFLOAT_MAX;
            CGFloat height = [_bundleDesc.cell cellSizeForBounds: frame].height;
            newDescHeight = 252 - height;
                        
            NSRect newRect = _viewDescription.frame;
            newRect.size.height = 309 - newDescHeight;
            [_viewDescription setFrame:newRect];
            
            diff += _viewDescription.frame.size.height;
        }
        diff += _viewInfo.frame.size.height;
           
        // Padding
        NSUInteger xPad = 10;
        NSUInteger yPad = 20;
        NSUInteger wide = self.superview.frame.size.width - (xPad * 2);
        
        // Current frame position
        NSUInteger currentYPos = diff;
        
        // Adjust container frame
        [self setFrameSize:CGSizeMake(self.frame.size.width, diff + yPad)];
    
        
        NSView *container = self.superview;
        [container setFrame:self.frame];
        [container setFrameOrigin:CGPointMake(0, 0)];
                
        // Header
        currentYPos -= _viewHeader.frame.size.height;
        [_viewHeader setFrame:CGRectMake(xPad, currentYPos, wide, _viewHeader.frame.size.height)];
        
        // Images
        if ([item objectForKey:@"hasPreview"]) {
            [_viewPreviews setHidden:false];
            currentYPos -= _viewPreviews.frame.size.height;
            [_viewPreviews setFrame:CGRectMake(xPad, currentYPos, wide, _viewPreviews.frame.size.height)];
        } else {
            [_viewPreviews setHidden:true];
        }
        
        // Description
        if (hasDescription) {
            [_viewDescription setHidden:false];
            currentYPos -= _viewDescription.frame.size.height;
            [_viewDescription setFrame:CGRectMake(xPad, currentYPos, wide, _viewDescription.frame.size.height)];
        } else {
            [_viewDescription setHidden:true];
        }
        
        // Info
        currentYPos -= _viewInfo.frame.size.height;
        [_viewInfo setFrame:CGRectMake(xPad, currentYPos, wide, _viewInfo.frame.size.height)];
        
//        [self.layer setBackgroundColor:NSColor.blueColor.CGColor];
//        [content.layer setBackgroundColor:[NSColor.redColor colorWithAlphaComponent:0.2].CGColor];
//        [self.containerView scrollPoint:CGPointZero];
    }
}

- (IBAction)shareMe:(id)sender {
    MF_Plugin *plugin = [MF_repoData sharedInstance].currentPlugin;
    
    if (plugin.webRepository) {
    }
    
    NSURL *shareURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", plugin.webRepository, plugin.bundleID]];
    shareURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"https://www.macenhance.com/mflink?macforge:%@", [shareURL resourceSpecifier]]];
    
//    NSURLComponents *components = [NSURLComponents new];
//    components.scheme = @"http";
//    components.host = @"joris.kluivers.nl";
//    components.path = @"/blog/2013/10/17/nsurlcomponents/";
//
//    NSURL *url = [components URL];
    
    NSLog(@"%@", shareURL);
    
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:shareURL.absoluteString forType:NSStringPboardType];
    
    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[shareURL]];
//    NSSharingServicePicker *sharingServicePicker = [[NSSharingServicePicker alloc] initWithItems:@[[NSURL URLWithString:@"https://www.macenhance.com/"]]];
//    sharingServicePicker.delegate = [[NSSharingServicePicker alloc] delegate];
    [sharingServicePicker showRelativeToRect:[sender bounds]
                                      ofView:sender
                               preferredEdge:NSMinYEdge];
}

- (IBAction)cyclePreviews:(id)sender {
//    NSLog(@"%lu", (unsigned long)_bundlePreviewImages.count);
    
    _bundlePreviewPrev.enabled = true;
    _bundlePreviewNext.enabled = true;
    
    if (_bundlePreviewImages.count > 2) {
        NSInteger increment;
        if ([sender isEqual:_bundlePreviewNext]) {
            increment = 2;
        } else {
            increment = -2;
        }
        
        if (increment < 0)
            if (_currentPreview == 0) {
                _bundlePreviewPrev.enabled = false;
                return;
            }
        
        if (increment > 0)
            if (_currentPreview >= _bundlePreviewImages.count - 2) {
                _bundlePreviewNext.enabled = false;
                return;
            }
            
        NSInteger newPreview = _currentPreview += increment;
        if (newPreview >= _bundlePreviewImages.count)
            newPreview = 0;
        else if (newPreview < 0)
            newPreview = _bundlePreviewImages.count - 1;
        
        _currentPreview = newPreview;
        self.bundlePreview1.image = self.bundlePreviewImages[newPreview];
        
        NSInteger secondPreview = newPreview + 1;
        if (secondPreview < _bundlePreviewImages.count)
            self.bundlePreview2.image = self.bundlePreviewImages[secondPreview];
        else
            self.bundlePreview2.image = self.bundlePreviewImages[0];
        
//        NSLog(@"Current preview : %lu : %lu", (unsigned long)_currentPreview, (unsigned long)secondPreview);
    }
}

- (void)verifyPurchased {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [MF_Purchase verifyPurchased:[MF_repoData sharedInstance].currentPlugin :self.bundleInstall];
    
//    NSString *myPaddleProductID = [item objectForKey:@"productID"];
//    if (myPaddleProductID != nil) {
//        NSString *myPaddleVendorID = @"26643";
//        NSString *myPaddleAPIKey = @"02a3c57238af53b3c465ef895729c765";
//
//        NSDictionary *dict = [item objectForKey:@"paddle"];
//        if (dict != nil) {
//            myPaddleVendorID = [dict objectForKey:@"vendorid"];
//            myPaddleAPIKey = [dict objectForKey:@"apikey"];
//        }
//
//        NSBundle *b = [NSBundle mainBundle];
//        NSString *execPath = [b pathForResource:@"purchaseValidationApp" ofType:@"app"];
//        execPath = [NSString stringWithFormat:@"%@/Contents/MacOS/purchaseValidationApp", execPath];
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSTask *task = [NSTask launchedTaskWithLaunchPath:execPath arguments:@[myPaddleProductID, myPaddleVendorID, myPaddleAPIKey, @"-v"]];
//            [task waitUntilExit];
//
//           //This is your completion handler
//           dispatch_sync(dispatch_get_main_queue(), ^{
//               if ([task terminationStatus] == 69) {
//                    NSLog(@"Verified...");
//                    self.bundleInstall.title = @"GET";
//                } else {
//                    self.bundleInstall.title = self.bundlePrice.stringValue;
//                }
//           });
//        });
//    }
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

- (void)contactDev {
    NSURL *mailtoURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [item objectForKey:@"contact"]]];
    [Workspace openURL:mailtoURL];
}

- (void)donateDev {
     [Workspace openURL:[NSURL URLWithString:[item objectForKey:@"donate"]]];
}

- (void)pluginInstall {
    [MF_PluginManager.sharedInstance pluginUpdateOrInstall:item :@"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo" withCompletionHandler:^(BOOL res) {
            [MF_PluginManager.sharedInstance readPlugins:nil];
            [self.bundleInstall setTitle:@"Open"];
            [self.bundleInstall setAction:@selector(pluginFinder)];
            [self.bundleDelete setEnabled:true];
            [self viewWillDraw];
    }];
}

- (void)pluginFinder {
    [MF_PluginManager.sharedInstance pluginRevealFinder:item];
}

- (void)pluginDelete {
    [MF_PluginManager.sharedInstance pluginDelete:item];
    [MF_PluginManager.sharedInstance readPlugins:nil];
    if ([[item objectForKey:@"payed"] boolValue]) {
        self.bundleInstall.title = @"Verifying...";
        [self verifyPurchased];
        [self.bundleInstall setAction:@selector(installOrPurchase)];
    } else {
        [self.bundleInstall setEnabled:true];
        self.bundleInstall.title = @"GET";
        [self.bundleInstall setAction:@selector(pluginInstall)];
    }
    [self.bundleDelete setEnabled:false];
    [self viewWillDraw];
}

- (IBAction)pluginShowImages:(id)sender {
//    NSLog(@"%lu", (unsigned long)self.bundlePreviewImages.count);
    
    if (self.bundlePreviewImages.count > 0) {
        MF_bundlePreviewView *v = (MF_bundlePreviewView*)myDelegate.viewImages;
        NSInteger curprev = self.currentPreview;
        
//        NSLog(@"%ld", (long)curprev);
        
        if ([sender isEqualTo:self.bundlePreviewButton2])
            if (curprev % 2 == 0)
                curprev++;
            
        NSView *mainViewHolder = self.superview.superview.superview.superview;
        
        if (curprev > self.bundlePreviewImages.count - 1) curprev = 0;
        v.currentPreview = curprev;
        v.bundlePreviewImages = self.bundlePreviewImages;
        [v.bundlePreview setImage:self.bundlePreviewImages[curprev]];
        [v setFrame:mainViewHolder.frame];
        [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
//        [v setFrameOrigin:NSMakePoint(0, 0)];
        [v setFrameOrigin:NSMakePoint(mainViewHolder.frame.size.width, 0)];
        [v setTranslatesAutoresizingMaskIntoConstraints:true];
        [mainViewHolder addSubview:v];
                
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [context setDuration:0.2];
            NSPoint startPoint = NSMakePoint(mainViewHolder.frame.size.width, 0);
            [v setFrameOrigin:startPoint];
            [[v animator] setFrameOrigin:NSMakePoint(0, 0)];
        } completionHandler:^{
        }];
    }
}

@end
