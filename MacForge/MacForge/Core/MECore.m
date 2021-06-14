//
//  MECore.m
//  Dark Boot
//
//  Created by Wolfgang Baird on 5/8/20.
//

#import "MECore.h"

void SafeRelease(CFTypeRef cf) {
    if (cf != nil) CFRelease(cf);
}

@implementation MF_FlippedView

-(BOOL)isFlipped {
    return YES;
}

@end

@implementation MECoreSBButton
@end

@implementation MECore

// Shared instance if needed
+ (MECore*) sharedInstance {
    static MECore* share = nil;
    if (share == nil)
        share = [[MECore alloc] init];
    return share;
}

+ (NSUInteger)macOS {
    return MECore.sharedInstance.macOS;
}

+ (NSColor*)blackOrWhite {
    NSColor *result = NSColor.blackColor;
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualToString:@"Dark"])
        result = NSColor.whiteColor;
    return result;
}

+ (void)rediecrLogToFolder:(NSString*)folder {
    // Some paths we'll need
    NSFileManager *fm = NSFileManager.defaultManager;
    NSString *name = NSBundle.mainBundle.executablePath.lastPathComponent;
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [[allPaths firstObject] stringByAppendingPathComponent:folder];
    NSString *pathForLog = [[appSupport stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"log"];

    // Make sure DockMate folder exists in ~/Library/Application Support
    if (![fm fileExistsAtPath:appSupport isDirectory:nil])
        [fm createDirectoryAtPath:appSupport withIntermediateDirectories:true attributes:nil error:nil];
        
    // Get size of log
    unsigned long long fileSize = [[fm attributesOfItemAtPath:pathForLog error:nil] fileSize];
    
    // Delete log if over 5MB
    if (fileSize > 5000000)
        [fm removeItemAtPath:pathForLog error:nil];
    
    // Redirect output to log
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

+ (void)whatsNew {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"BuildNumber"];
    NSString *displayedBuild = [NSUserDefaults.standardUserDefaults stringForKey:@"CDWelcomeBuild"];
    
    if (![appVersion isEqualToString:displayedBuild]) {
    
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Okay"];
        NSString *text = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
        NSArray *versions = [text componentsSeparatedByString:@"###"];
        text = versions[1];
        
        int viewHeight = 0;
        int origin = 0;
        NSView *customView = [NSView.alloc initWithFrame:NSMakeRect(0, 0, 400, 0)];
        
        NSTextField *warning = NSTextField.new;
        [warning setStringValue:text];
        CGFloat minHeight = [((NSTextFieldCell *)[warning cell]) cellSizeForBounds:NSMakeRect(0, 0, 364, FLT_MAX)].height;
        [warning setFrame:NSMakeRect(18, origin, 364, minHeight)];
        [warning setSelectable:false];
        [warning setDrawsBackground:false];
        [warning setBordered:false];
        viewHeight += minHeight;
        origin += minHeight;
        [customView addSubview:warning];
        
        [customView setFrame:NSMakeRect(0, 0, 400, viewHeight)];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert setMessageText:[NSString stringWithFormat:@"Here's what's new in %@ (%@)", appVersion, buildNumber]];
        [alert setAccessoryView:customView];
        
        if (NSApp.mainWindow.isVisible) {
            [alert beginSheetModalForWindow:NSApp.mainWindow completionHandler:^(NSModalResponse returnCode) {
                // Okay...
                [NSUserDefaults.standardUserDefaults setObject:appVersion forKey:@"CDWelcomeBuild"];
            }];
        } else {
            [alert runModal];
            [NSUserDefaults.standardUserDefaults setObject:appVersion forKey:@"CDWelcomeBuild"];
        }
    
    }
}

+ (BOOL)hasLoggedCurrentVersion {
    NSString *logVer = [NSUserDefaults.standardUserDefaults valueForKey:@"lastLoggedVersion"];
    NSString *appVer = [NSBundle.mainBundle.infoDictionary valueForKey:@"CFBundleVersion"];
    if ([logVer isEqualToString:appVer])
        return true;
    [NSUserDefaults.standardUserDefaults setValue:appVer forKey:@"lastLoggedVersion"];
    return false;
}

+ (void)logInfo:(BOOL)activated {
    [NSUserDefaults.standardUserDefaults setBool:activated forKey:@"hasActivated"];
    CFStringRef yourFriendlyCFString = (__bridge CFStringRef)NSBundle.mainBundle.bundlePath;
    SecStaticCodeRef codeRef;
    CFURLRef appURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, yourFriendlyCFString, kCFURLPOSIXPathStyle, YES);
    SecStaticCodeCreateWithPath(appURL, kSecCSDefaultFlags, &codeRef);
    CFRelease(appURL);
    CFDictionaryRef signDic;
    SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &signDic);
    if (!CFDictionaryContainsKey(signDic,kSecCodeInfoIdentifier)) {
        
        NSLog(@"Bundle not signed....");
        [MSACAnalytics trackEvent:@"Activation Status" withProperties:@{
            @"activated" : [NSString stringWithFormat:@"%hhd", activated],
            @"bundleID"  : NSBundle.mainBundle.bundleIdentifier,
            @"teamID"    : @"Unsigned"
        }];
    
    } else {
        
        NSDictionary *andBack = (__bridge NSDictionary*)signDic;
        NSArray *certs = [andBack valueForKey:@"certificates"];
        if (certs.count > 0) {
            id cert = certs[0];
            SecCertificateRef certificate = (__bridge SecCertificateRef)(cert);
            NSDictionary* dict = (NSDictionary*)CFBridgingRelease( SecCertificateCopyValues(certificate, NULL, NULL) );
            if (dict) {
                NSDictionary *d = [dict valueForKey:@"2.16.840.1.113741.2.1.1.1.8"];
                NSArray *a = [d valueForKey:@"value"];
                if (a.count > 1) {
                    NSString *TeamIdentifier = [a[2] valueForKey:@"value"];
                    NSLog(@"Bundle signed with : %@", TeamIdentifier);
                    [MSACAnalytics trackEvent:@"Activation Status" withProperties:@{
                        @"activated" : [NSString stringWithFormat:@"%hhd", activated],
                        @"bundleID"  : NSBundle.mainBundle.bundleIdentifier,
                        @"teamID"    : TeamIdentifier
                    }];
                }
            }
        }

    }
    CFRelease(signDic);
}

- (instancetype)init {
    MECore *res = [super init];
    self.macOS = 9;
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 11) {
        // Big Sur or newer
        self.macOS = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion + 5;
    } else {
        // Catalina or older
        self.macOS = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    }
    return res;
}

- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

- (void)setupSidebar11 {
    // Setup top buttons
    NSInteger height = 36;
    NSUInteger totalHeight = height * 2;
    NSUInteger yLoc = self.mainView.window.frame.size.height - height * 2 - 50;
    for (MECoreSBButton *sideButton in self.sidebarTopButtons) {
        
        // Setup click area
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            [btn setTarget:self];
            [btn setAction:@selector(selectView:)];
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = height;
            yLoc -= height;
            totalHeight += height;
            sideButton.hidden = false;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
            sideButton.layer.backgroundColor = NSColor.clearColor.CGColor;
        } else {
            sideButton.hidden = true;
        }
        
        // Image setup
        sideButton.buttonImage.frame = CGRectMake(18, 8, 20, 20);
        if (!sideButton.buttonImage.image.isTemplate) [sideButton.buttonImage.image setTemplate:true];
        if (@available(macOS 10.14, *)) sideButton.buttonImage.contentTintColor = NSColor.controlAccentColor;
        
        // Label setup
        CGRect labelFrame = sideButton.buttonLabel.frame;
        labelFrame.origin.x = 46;
        labelFrame.origin.y = 6;
        sideButton.buttonLabel.frame = labelFrame;
        [sideButton.buttonLabel setFont:[NSFont systemFontOfSize:16]];
        
        // Backing area setup
        sideButton.buttonHighlightArea.frame = CGRectMake(8, 1, sideButton.frame.size.width - 16, 34);
        sideButton.buttonHighlightArea.wantsLayer = true;
        sideButton.buttonHighlightArea.layer.cornerRadius = 5;
        
        // Extra
        if (sideButton.buttonExtra) {
            CGRect extra = sideButton.buttonExtra.frame;
            extra.origin.y = (sideButton.frame.size.height - sideButton.buttonExtra.frame.size.height) / 2 - 2;
            sideButton.buttonExtra.frame = extra;
        }
    }
        
    // Setup bottom buttons
    height = 58;
    yLoc = 0;
    for (MECoreSBButton *sideButton in self.sidebarBotButtons) {
        
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            sideButton.hidden = false;
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = height;
            yLoc += height;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
        } else {
            sideButton.hidden = true;
        }
        
        CGRect labelFrame = sideButton.buttonImage.frame;
        labelFrame.origin.x = 8;
        sideButton.buttonImage.frame = labelFrame;
    }
    
    MECoreSBButton *sideButton = self.sidebarBotButtons.firstObject;
    if (!sideButton.buttonImage.image.isTemplate) [sideButton.buttonImage.image setTemplate:true];
    if (@available(macOS 10.14, *)) sideButton.buttonImage.contentTintColor = NSColor.controlAccentColor;
    
    totalHeight += yLoc - 6;
    CGSize min = CGSizeMake(1000, totalHeight + 10);
    [self.mainWindow setMinSize:min];
    if (self.mainWindow.frame.size.height < min.height) {
        CGRect frm = self.mainWindow.frame;
        [self.mainWindow setFrame:CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, min.height + 16) display:true];
    }
}

- (void)setupSidebar {
    if (self.macOS >= 16) {
        [self setupSidebar11];
        return;
    }
    
    // Setup top buttons
    NSInteger height = 42;
    NSInteger resizeWidth = 24;
    NSUInteger totalHeight = height * 2;
    NSUInteger yLoc = self.mainView.window.frame.size.height - height * 2 - 40;
    for (MECoreSBButton *sideButton in self.sidebarTopButtons) {
        
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            sideButton.hidden = false;
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = height;
            yLoc -= height;
            totalHeight += height;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
        } else {
            sideButton.hidden = true;
        }
        
        [sideButton.buttonLabel setFont:[NSFont systemFontOfSize:18]];
        
        if (sideButton.buttonImage.image.size.width > resizeWidth && sideButton.buttonImage.image.size.height != 30)
            sideButton.buttonImage.image = [self imageResize:sideButton.buttonImage.image newSize:CGSizeMake(resizeWidth, sideButton.buttonImage.image.size.height * (resizeWidth / sideButton.buttonImage.image.size.height))];
        
        // Image setup
        if (!sideButton.buttonImage.image.isTemplate) [sideButton.buttonImage.image setTemplate:true];
        if (@available(macOS 10.14, *)) sideButton.buttonImage.contentTintColor = NSColor.controlAccentColor;
        
        sideButton.buttonHighlightArea.wantsLayer = true;
    }

    // Set target + action
    for (MECoreSBButton *sideButton in self.sidebarTopButtons) {
        NSButton *btn = sideButton.buttonClickArea;
        [btn setTarget:self];
        [btn setAction:@selector(selectView:)];
    }
        
    // Setup bottom buttons
    height = 60;
    yLoc = 10;
    for (MECoreSBButton *sideButton in self.sidebarBotButtons) {
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            sideButton.hidden = false;
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = height;
            yLoc += height;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
        } else {
            sideButton.hidden = true;
        }
    }
    
    MECoreSBButton *sideButton = self.sidebarBotButtons.firstObject;
    if (!sideButton.buttonImage.image.isTemplate) [sideButton.buttonImage.image setTemplate:true];
    if (@available(macOS 10.14, *)) sideButton.buttonImage.contentTintColor = NSColor.controlAccentColor;
    
    totalHeight += yLoc - 6;
    CGSize min = CGSizeMake(1000, totalHeight);
    [self.mainWindow setMinSize:min];
    if (self.mainWindow.frame.size.height < min.height) {
        CGRect frm = self.mainWindow.frame;
        [self.mainWindow setFrame:CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, min.height + 16) display:true];
    }
}

- (void)updateSidebarColor {
    // Adjust text and background color
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSColor *primary = NSColor.darkGrayColor;
    NSColor *secondary = NSColor.blackColor;
    NSColor *highlight = NSColor.blackColor;
    if (self.macOS >= 14) {
        if ([osxMode isEqualToString:@"Dark"]) {
            primary = NSColor.whiteColor;
            secondary = NSColor.whiteColor;
            highlight = NSColor.whiteColor;
        }
    }
    
    NSMutableArray *allButtons = self.sidebarTopButtons.mutableCopy;
    [allButtons addObjectsFromArray:self.sidebarBotButtons];
    for (MECoreSBButton *sidebarButton in allButtons) {
        NSTextField *g = sidebarButton.buttonLabel;
        NSMutableAttributedString *colorTitle = [NSMutableAttributedString.alloc initWithString:g.stringValue];
        if (!sidebarButton.selected) {
            sidebarButton.buttonHighlightArea.layer.backgroundColor = [NSColor clearColor].CGColor;
            [colorTitle addAttribute:NSForegroundColorAttributeName value:primary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        } else {
            sidebarButton.buttonHighlightArea.layer.backgroundColor = [highlight colorWithAlphaComponent:.11].CGColor;
            [colorTitle addAttribute:NSForegroundColorAttributeName value:secondary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        }
    }
}

- (IBAction)selectView:(id)sender {
    MECoreSBButton *buttonContainer = nil;
    NSButton *button = (NSButton*)sender;
    if (button.superview.class == MECoreSBButton.class) {
        buttonContainer = (MECoreSBButton*)button.superview;
    } else if ([sender class] == MECoreSBButton.class) {
        buttonContainer = (MECoreSBButton*)sender;
        button = buttonContainer.buttonClickArea;
    }
           
    // Select the view
    if (buttonContainer) {
        // Log that the user clicked on a sidebar button
        [MSACAnalytics trackEvent:@"Selected View" withProperties:@{@"View" : [button title]}];
        // Add the view to our main view
        [self setMainViewSubView:buttonContainer.linkedView];
    }
    
    NSMutableArray *allButtons = self.sidebarTopButtons.mutableCopy;
    [allButtons addObjectsFromArray:self.sidebarBotButtons];
    for (MECoreSBButton *sidebarButton in allButtons)
        sidebarButton.selected = false;
    buttonContainer.selected = true;
    [self updateSidebarColor];
}

- (void)setViewSubViewWithScrollableView:(NSView*)view :(NSView*)subview {
    // configure the scroll view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:[view frame]];
    [scrollView setFrameOrigin:CGPointMake(0, 0)];
    [scrollView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable | NSViewMinYMargin];
    [scrollView setBorderType:NSNoBorder];
    [scrollView setHasVerticalScroller:YES];
    scrollView.automaticallyAdjustsContentInsets = false;
    scrollView.drawsBackground = false;
    
    // configure document view
    MF_FlippedView *docView = [[MF_FlippedView alloc] initWithFrame:NSMakeRect(0, 0, view.frame.size.width, subview.frame.size.height)];
    docView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;

    // configure our subview
    [subview setFrameOrigin:CGPointMake((docView.frame.size.width - subview.frame.size.width)/2, 0)];
    subview.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;

    // embed views
    [docView setSubviews:@[subview]];
    [scrollView setDocumentView:docView];
    [view setSubviews:@[scrollView]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [docView setFrameSize:CGSizeMake(view.frame.size.width, docView.frame.size.height)];
    });
}

- (void)setMainViewSubView:(NSView*)subview {
    [subview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [subview setFrameSize:CGSizeMake(self.mainView.frame.size.width, self.mainView.frame.size.height - 2)];
    [self.mainView setSubviews:@[subview]];
}

- (IBAction)selectPreference:(id)sender {
    NSView *selectedPane = [self.preferenceViews objectAtIndex:[(NSSegmentedControl*)sender selectedSegment]];
    [self.prefWindow.contentView setSubviews:@[selectedPane]];
    
    NSVisualEffectView *vibrant = [[NSVisualEffectView alloc] initWithFrame:[[self.prefWindow contentView] bounds]];
    [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [vibrant setState:NSVisualEffectStateActive];
    [[self.prefWindow contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    
    CGRect newFrame = self.prefWindow.frame;
    CGFloat contentHeight = [self.prefWindow contentRectForFrameRect: self.prefWindow.frame].size.height;
    CGFloat titleHeight = self.prefWindow.frame.size.height - contentHeight;
    newFrame.size.height = selectedPane.frame.size.height + titleHeight;
    newFrame.size.width = selectedPane.frame.size.width;
    
//    NSLog(@"%f", newFrame.size.width);
//    NSLog(@"%f", self.prefToolbar.view.frame.size.width);
//    if (newFrame.size.width - 110 < self.prefToolbar.view.frame.size.width)
//        newFrame.size.width =  self.prefToolbar.view.frame.size.width + 110;
        
    CGFloat yDiff = self.prefWindow.frame.size.height - newFrame.size.height;
    newFrame.origin.y += yDiff;
    [self.prefWindow setFrame:newFrame display:true animate:true];
    self.prefWindow.styleMask &= ~NSWindowStyleMaskResizable;
    
    if (![self.prefWindow.toolbar.visibleItems containsObject:self.prefToolbar]) {
        newFrame.size.width = self.prefToolbar.view.frame.size.width + 110;
        if (newFrame.size.width < selectedPane.frame.size.width)
            newFrame.size.width = selectedPane.frame.size.width;
    }
    [self.prefWindow setFrame:newFrame display:true animate:true];
        
    // Center the window in our main window
    if (self.mainWindow.isVisible) {
        if (![self.prefWindow isVisible]) {
            NSRect frm      = self.mainWindow.frame;
            NSRect myfrm    = self.prefWindow.frame;
            [self.prefWindow setFrameOrigin:CGPointMake(frm.origin.x + frm.size.width / 2 - myfrm.size.width / 2,
                                                    frm.origin.y + frm.size.height / 2 - myfrm.size.height / 2)];
        }
    } else {
        if (![self.prefWindow isVisible])
            [self.prefWindow center];
    }
    
    // Focus the window
    [NSApp activateIgnoringOtherApps:true];
    [self.prefWindow setIsVisible:true];
    [self.prefWindow makeKeyWindow];
    [self.prefWindow makeKeyAndOrderFront:self];
    
    BOOL showAsChild = false;
    if (self.mainWindow)
        if (self.mainWindow.isVisible)
            showAsChild = true;
    
    if (showAsChild)
        [self.mainWindow addChildWindow:self.prefWindow ordered:NSWindowAbove];
    else
        [self.prefWindow makeKeyAndOrderFront:nil];
}

- (IBAction)selectAboutInfo:(id)sender {
    NSUInteger selected = [(NSSegmentedControl*)sender selectedSegment];
    
    if (selected == 0) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [self.changeLog.textStorage setAttributedString:asr.render];
    }
    if (selected == 1) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CREDITS" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [self.changeLog.textStorage setAttributedString:asr.render];
    }
    if (selected == 2) {
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] init];
        for (NSString *item in [NSFileManager.defaultManager contentsOfDirectoryAtPath:NSBundle.mainBundle.resourcePath error:nil]) {
            if ([item containsString:@"LICENSE"]) {
                
                NSString *unicodeStr = @"\n\u00a0\t\t\n\n";
                NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:unicodeStr];
                NSRange strRange = NSMakeRange(0, str.length);

                NSMutableParagraphStyle *const tabStyle = [[NSMutableParagraphStyle alloc] init];
                tabStyle.headIndent = 16; //padding on left and right edges
                tabStyle.firstLineHeadIndent = 16;
                tabStyle.tailIndent = -70;
                NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentCenter location:self.changeLog.frame.size.width - tabStyle.headIndent + tabStyle.tailIndent options:@{}]; //this is how long I want the line to be
                tabStyle.tabStops = @[listTab];
                [str  addAttribute:NSParagraphStyleAttributeName value:tabStyle range:strRange];
                [str addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:2] range:strRange];
                
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:item withExtension:@""] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
                [mutableAttString appendAttributedString:str];
            }
        }
        [self.changeLog.textStorage setAttributedString:mutableAttString];
    }
//    if (selected == 3) {
//        NSString *path = [[[NSBundle mainBundle] URLForResource:@"README" withExtension:@"md"] path];
//        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
//        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
//        [self.changeLog.textStorage setAttributedString:asr.render];
//    }
    
    [NSAnimationContext beginGrouping];
    NSClipView* clipView = self.changeLog.enclosingScrollView.contentView;
    NSPoint newOrigin = [clipView bounds].origin;
    newOrigin.y = 0;
    [[clipView animator] setBoundsOrigin:newOrigin];
    [NSAnimationContext endGrouping];
    
    [self systemDarkModeChange:nil];
}

// Cleanup some stuff when user changes dark mode
- (void)systemDarkModeChange:(NSNotification *)notif {
    if (self.macOS >= 14) {
        if (notif == nil) {
            // Need to fix for older versions of macos
            [self.changeLog setTextColor:[NSColor whiteColor]];
            if ([NSApp.effectiveAppearance.name isEqualToString:NSAppearanceNameAqua])
                [self.changeLog setTextColor:[NSColor blackColor]];
        } else {
            NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
            [self.changeLog setTextColor:[NSColor blackColor]];
            if ([osxMode isEqualToString:@"Dark"])
                [self.changeLog setTextColor:[NSColor whiteColor]];
        }
        [self updateSidebarColor];
    }
}

- (void)email {
    NSDictionary* infoDict = NSBundle.mainBundle.infoDictionary;
    NSString *appVersion = [NSString stringWithFormat:@"Version %@ (Build %@)", [infoDict objectForKey:@"CFBundleShortVersionString"], [infoDict objectForKey:@"CFBundleVersion"]];
    NSString *appName = [infoDict objectForKey:@"CFBundleExecutable"];
    NSString *macOS = NSProcessInfo.processInfo.operatingSystemVersionString;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    NSDate *date = NSDate.date; // [NSDate dateWithTimeIntervalSinceReferenceDate:118800];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"enself.US"];
    NSString *body = [NSString stringWithFormat:@"%@\n%@ : %@\nmacOS : %@", [dateFormatter stringFromDate:date], appName, appVersion, macOS];
    NSString *mailString = [NSString stringWithFormat:@"mailto:?to=%@&subject=%@&body=%@",
                            [@"support@macenhance.com" stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet],
                            [[appName stringByAppendingString:@" Feedback"] stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet],
                            [body stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet]];
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:mailString]];
}

@end
