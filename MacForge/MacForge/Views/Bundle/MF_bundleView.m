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
    
    if (testing) {
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
    }
    
    // End reviews
    
    _bundleRequiresLIB.hidden = true;
    _bundleRequiresSIP.hidden = true;
    
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
    
    _plugin = [MF_repoData sharedInstance].currentPlugin;
    if (_plugin != nil)
        item = _plugin.webPlist;
        
    NSString* newString;
    newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"name"]];
    [self.bundleName setFont:[self calcFontSizeToFitRect:self.bundleName.frame :newString :self.bundleName.font.fontName]];
    self.bundleName.stringValue = newString;
    
    if (![_currentBundle isEqualToString:newString]) {
        _currentBundle = newString;
        
        newString = [NSString stringWithFormat:@"%@", [item objectForKey:@"description"]];
        [self.bundleDesc setAttributedStringValue:[[NSMutableAttributedString alloc] initWithString:newString]];
        [self.bundleDesc setAllowsEditingTextAttributes:false];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self->item[@"markdown"]) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/readme.md", self.plugin.webRepository, self.plugin.bundleID]];
                NSData *fetch = [[NSData alloc] initWithContentsOfURL:url];
                if (fetch.length) {
                    CMDocument *cmd = [CMDocument.alloc initWithData:fetch options:CMDocumentOptionsNormalize];
                    CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.bundleDesc setAttributedStringValue:asr.render];
                        [self.bundleDesc setAllowsEditingTextAttributes:true];
                        [self resizeME];
                    });
                }
            }
        });
        
        [self systemDarkModeChange:nil];
        
        if (@available(macOS 10.14, *)) {
            [self.bundleDev setContentTintColor:NSColor.controlAccentColor];
            [self.bundleContact setContentTintColor:NSColor.controlAccentColor];
            [self.bundleDelete setContentTintColor:NSColor.controlAccentColor];
            [self.bundleDonate setContentTintColor:NSColor.controlAccentColor];
        } else {
            // Fallback on earlier versions
        }
        
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
        self.bundleDev.title = newString;
        [self.bundleDev setTarget:self];
        [self.bundleDev setAction:@selector(showDevTweaks)];
        
        // Seller
        _bundleSeller.stringValue = newString;
        
        // Copyright
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
        
        [self.bundleDelete setTarget:self];
        [self.bundleDelete setAction:@selector(pluginDelete)];
        
        [self.bundleDelete setEnabled:[MF_PluginManager.sharedInstance pluginLocalPath:_plugin.bundleID].length];
          
        [MF_Purchase checkStatus:_plugin :_bundleInstall];
        
        if (@available(macOS 10.14, *)) {
            _bundleInstall.backgroundNormalColor = NSColor.controlAccentColor;
        } else {
            _bundleInstall.backgroundNormalColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
        }
        _bundleInstall.backgroundHighlightColor = NSColor.whiteColor;
        _bundleInstall.backgroundDisabledColor = NSColor.grayColor;
        _bundleInstall.titleNormalColor = NSColor.whiteColor;
        _bundleInstall.titleHighlightColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
        _bundleInstall.titleDisabledColor = NSColor.whiteColor;
        _bundleInstall.cornerRadius = _bundleInstall.frame.size.height/2;
        if (@available(macOS 10.15, *)) { _bundleInstall.layer.cornerCurve = kCACornerCurveContinuous; }
        _bundleInstall.spacing = 0.1;
        _bundleInstall.borderWidth = 0;
        _bundleInstall.momentary = true;
        _bundleInstall.action = @selector(getOrOpen:);
        _bundleInstall.target = self;
        
        self.bundlePreview1.animates = YES;
        self.bundlePreview1.canDrawSubviewsIntoLayer = YES;
        self.bundlePreview1.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        self.bundlePreview2.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
        
        _bundlePreviewImages = @[[[NSImage alloc] init], [[NSImage alloc] init]];
        NSString *bundle = [NSString stringWithFormat:@"%@", [self->item objectForKey:@"package"]];
        
        _currentPreview = 0;
        NSMutableArray *abc = [[NSMutableArray alloc] init];
        for (int i = 1; i <= 6; i++) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/previewImages/0%u.png", MF_REPO_URL, bundle, i]];
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
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSImage *a = [NSImage.alloc initWithContentsOfURL:abc[0]];
            NSColor *newColor = [[SLColorArt.alloc initWithImage:a].backgroundColor colorWithAlphaComponent:0.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.bundlePreview1.layer.backgroundColor = newColor.CGColor;
            });
        });
        
        [self.bundlePreview2 sd_setImageWithURL:abc[1]
                               placeholderImage:[UIImage imageNamed:NSImageNameBookmarksTemplate]];
        
        self.bundlePreview2.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
        self.bundlePreview2.layer.cornerRadius = 5;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSImage *b = [NSImage.alloc initWithContentsOfURL:abc[1]];
            NSColor *newColor = [[SLColorArt.alloc initWithImage:b].backgroundColor colorWithAlphaComponent:0.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.bundlePreview2.layer.backgroundColor = newColor.CGColor;
            });
        });
                    
        if (_plugin.webPlist[@"icon"] || _plugin.webPlist[@"customIcon"]) {
            self.bundleImage.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
            self.bundleImage.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
            [self.bundleImage sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/icon.png", MF_REPO_URL, _plugin.bundleID]]
                                 placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
        } else {
            NSImage *icon = [MF_PluginManager pluginGetIcon:_plugin.webPlist];
            self.bundleImage.image = icon;
        }
        
        [self.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        
        [self resizeME];
    }
}

- (void)resizeME {
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
        newDescHeight = 250 - height;

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
}

- (IBAction)getOrOpen:(id)sender {
    [MF_Purchase pushthebutton:_plugin :sender :MF_REPO_URL :_bundleProgress];
}

- (IBAction)shareMe:(id)sender {
    MF_Plugin *plugin = [MF_repoData sharedInstance].currentPlugin;
    
    if (plugin.webRepository) {
    }
    
    NSURL *shareURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", _plugin.webRepository, _plugin.bundleID]];
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
        
        NSImage *test;
        
        test = self.bundlePreview1.image;
        if (!test.sd_isAnimated)
            self.bundlePreview1.layer.backgroundColor = [[SLColorArt.alloc initWithImage:test].backgroundColor colorWithAlphaComponent:0.5].CGColor;
        
        test = self.bundlePreview2.image;
        if (!test.sd_isAnimated)
            self.bundlePreview2.layer.backgroundColor = [[SLColorArt.alloc initWithImage:test].backgroundColor colorWithAlphaComponent:0.5].CGColor;
        
//        NSLog(@"Current preview : %lu : %lu", (unsigned long)_currentPreview, (unsigned long)secondPreview);
    }
}

- (void)showDevTweaks {
    [myDelegate.searchPlugins setStringValue:[_bundleID.stringValue stringByDeletingPathExtension]];
    [myDelegate updatesearchText];
}

- (void)contactDev {
    NSURL *mailtoURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", [item objectForKey:@"contact"]]];
    [Workspace openURL:mailtoURL];
}

- (void)donateDev {
     [Workspace openURL:[NSURL URLWithString:[item objectForKey:@"donate"]]];
}

- (void)pluginFinder {
    [MF_PluginManager.sharedInstance pluginRevealFinder:item];
}

- (void)pluginDelete {
    [MF_PluginManager.sharedInstance pluginDelete:item];
    [MF_PluginManager.sharedInstance readPlugins:nil];
    [MF_Purchase checkStatus:_plugin :self.bundleInstall];
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
