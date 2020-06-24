//
//  MF_extra.m
//  Dark Boot
//
//  Created by Wolfgang Baird on 5/8/20.
//

#import "MF_extra.h"

@implementation MF_FlippedView

-(BOOL)isFlipped {
    return YES;
}

@end

@implementation MF_sidebarButton
@end

@implementation MF_extra

// Shared instance if needed
+ (MF_extra*) sharedInstance {
    static MF_extra* share = nil;
    if (share == nil)
        share = [[MF_extra alloc] init];
    return share;
}

- (instancetype)init {
    MF_extra *res = [super init];
    _macOS = 9;
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)])
        _macOS = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
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
    NSInteger resizeWidth = 18;
    NSUInteger totalHeight = height * 2;
    NSUInteger yLoc = _mainView.window.frame.size.height - height * 2 - 50;
    for (MF_sidebarButton *sideButton in _sidebarTopButtons) {
        
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
    for (MF_sidebarButton *sideButton in _sidebarBotButtons) {
        
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
    
    totalHeight += yLoc - 6;
    CGSize min = CGSizeMake(1000, totalHeight);
    [_mainWindow setMinSize:min];
    if (_mainWindow.frame.size.height < min.height) {
        CGRect frm = _mainWindow.frame;
        [_mainWindow setFrame:CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, min.height + 16) display:true];
    }
}

- (void)setupSidebar {
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 16) {
        [self setupSidebar11];
        return;
    }
    
    // Setup top buttons
    NSInteger height = 42;
    NSInteger resizeWidth = 24;
    NSUInteger totalHeight = height * 2;
    NSUInteger yLoc = _mainView.window.frame.size.height - height * 2 - 50;
    for (MF_sidebarButton *sideButton in _sidebarTopButtons) {
        
        if (sideButton.buttonImage.image.size.width > resizeWidth && sideButton.buttonImage.image.size.height != 30)
            sideButton.buttonImage.image = [self imageResize:sideButton.buttonImage.image newSize:CGSizeMake(resizeWidth, sideButton.buttonImage.image.size.height * (resizeWidth / sideButton.buttonImage.image.size.height))];
        
        if (!sideButton.buttonImage.image.isTemplate)
            [sideButton.buttonImage.image setTemplate:true];
        
        if (@available(macOS 10.14, *)) sideButton.buttonImage.contentTintColor = NSColor.controlAccentColor;
        
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
        
        sideButton.buttonHighlightArea.wantsLayer = true;
    }

    // Set target + action
    for (MF_sidebarButton *sideButton in _sidebarTopButtons) {
        NSButton *btn = sideButton.buttonClickArea;
        [btn setTarget:self];
        [btn setAction:@selector(selectView:)];
    }
        
    // Setup bottom buttons
    height = 60;
    yLoc = 10;
    for (MF_sidebarButton *sideButton in _sidebarBotButtons) {
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
    
    totalHeight += yLoc - 6;
    CGSize min = CGSizeMake(1000, totalHeight);
    [_mainWindow setMinSize:min];
    if (_mainWindow.frame.size.height < min.height) {
        CGRect frm = _mainWindow.frame;
        [_mainWindow setFrame:CGRectMake(frm.origin.x, frm.origin.y, frm.size.width, min.height + 16) display:true];
    }
}

- (void)updateSidebarColor {
    // Adjust text and background color
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSColor *primary = NSColor.darkGrayColor;
    NSColor *secondary = NSColor.blackColor;
    NSColor *highlight = NSColor.blackColor;
    if (_macOS >= 14) {
        if ([osxMode isEqualToString:@"Dark"]) {
            primary = NSColor.whiteColor;
            secondary = NSColor.whiteColor;
            highlight = NSColor.whiteColor;
        }
    }
    
    NSMutableArray *allButtons = _sidebarTopButtons.mutableCopy;
    [allButtons addObjectsFromArray:_sidebarBotButtons];
    for (MF_sidebarButton *sidebarButton in allButtons) {
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
    MF_sidebarButton *buttonContainer = nil;
    NSButton *button = (NSButton*)sender;
    if (button.superview.class == MF_sidebarButton.class) {
        buttonContainer = (MF_sidebarButton*)button.superview;
    } else if ([sender class] == MF_sidebarButton.class) {
        buttonContainer = (MF_sidebarButton*)sender;
        button = buttonContainer.buttonClickArea;
    }
           
    // Select the view
    if (buttonContainer) {
        // Log that the user clicked on a sidebar button
        [MSAnalytics trackEvent:@"Selected View" withProperties:@{@"View" : [button title]}];
        // Add the view to our main view
        [self setMainViewSubView:buttonContainer.linkedView];
    }
    
    NSMutableArray *allButtons = _sidebarTopButtons.mutableCopy;
    [allButtons addObjectsFromArray:_sidebarBotButtons];
    for (MF_sidebarButton *sidebarButton in allButtons)
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
    scrollView.drawsBackground = false;
//    scrollView.backgroundColor = NSColor.clearColor;

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
    [subview setFrameSize:CGSizeMake(_mainView.frame.size.width, _mainView.frame.size.height - 2)];
    [_mainView setSubviews:@[subview]];
}

- (IBAction)selectPreference:(id)sender {
    NSView *selectedPane = [_preferenceViews objectAtIndex:[(NSSegmentedControl*)sender selectedSegment]];
    [_prefWindow.contentView setSubviews:@[selectedPane]];
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_prefWindow contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_prefWindow contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    }
    CGRect newFrame = _prefWindow.frame;
    CGFloat contentHeight = [_prefWindow contentRectForFrameRect: _prefWindow.frame].size.height;
    CGFloat titleHeight = _prefWindow.frame.size.height - contentHeight;
    newFrame.size.height = selectedPane.frame.size.height + titleHeight;
    newFrame.size.width = selectedPane.frame.size.width;
    CGFloat yDiff = _prefWindow.frame.size.height - newFrame.size.height;
    newFrame.origin.y += yDiff;
    [_prefWindow setFrame:newFrame display:true animate:true];
    _prefWindow.styleMask &= ~NSWindowStyleMaskResizable;
    
    // Center the window in our main window
    if (![_prefWindow isVisible]) {
        NSRect frm      = NSApp.mainWindow.frame;
        NSRect myfrm    = _prefWindow.frame;
        [_prefWindow setFrameOrigin:CGPointMake(frm.origin.x + frm.size.width / 2 - myfrm.size.width / 2,
                                                frm.origin.y + frm.size.height / 2 - myfrm.size.height / 2)];
    }
    
    // Focus the window
    [NSApp activateIgnoringOtherApps:true];
    [_prefWindow setIsVisible:true];
    [_prefWindow makeKeyWindow];
    [_prefWindow makeKeyAndOrderFront:self];
}

- (IBAction)selectAboutInfo:(id)sender {
    NSUInteger selected = [(NSSegmentedControl*)sender selectedSegment];
    
    if (selected == 0) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
    }
    if (selected == 1) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CREDITS" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
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
                NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentCenter location:_changeLog.frame.size.width - tabStyle.headIndent + tabStyle.tailIndent options:@{}]; //this is how long I want the line to be
                tabStyle.tabStops = @[listTab];
                [str  addAttribute:NSParagraphStyleAttributeName value:tabStyle range:strRange];
                [str addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:2] range:strRange];
                
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:item withExtension:@""] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
                [mutableAttString appendAttributedString:str];
            }
        }
        [_changeLog.textStorage setAttributedString:mutableAttString];
    }
    if (selected == 3) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"README" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
    }
    
    [NSAnimationContext beginGrouping];
    NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
    NSPoint newOrigin = [clipView bounds].origin;
    newOrigin.y = 0;
    [[clipView animator] setBoundsOrigin:newOrigin];
    [NSAnimationContext endGrouping];
    
    [self systemDarkModeChange:nil];
}

// Cleanup some stuff when user changes dark mode
- (void)systemDarkModeChange:(NSNotification *)notif {
    if (_macOS >= 14) {
        if (notif == nil) {
            // Need to fix for older versions of macos
            [_changeLog setTextColor:[NSColor whiteColor]];
            if ([NSApp.effectiveAppearance.name isEqualToString:NSAppearanceNameAqua])
                [_changeLog setTextColor:[NSColor blackColor]];
        } else {
            NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
            [_changeLog setTextColor:[NSColor blackColor]];
            if ([osxMode isEqualToString:@"Dark"])
                [_changeLog setTextColor:[NSColor whiteColor]];
        }
        [self updateSidebarColor];
    }
}

@end
