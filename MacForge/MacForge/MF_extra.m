//
//  MF_extra.m
//  Dark Boot
//
//  Created by Wolfgang Baird on 5/8/20.
//

#import "MF_extra.h"
#import "MFFlippedView.h"

@implementation MF_sidebarButton
@end

@implementation MF_extra

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

- (void)setupSidebar {
    // Setup top buttons
    NSInteger height = 42;
    NSUInteger yLoc = _mainView.window.frame.size.height - height * 2;
    yLoc -= 50;
    for (MF_sidebarButton *sideButton in _sidebarTopButtons) {
        if (sideButton.buttonImage.image.size.width > 18 && sideButton.buttonImage.image.size.height != 30)
            sideButton.buttonImage.image = [self imageResize:sideButton.buttonImage.image newSize:CGSizeMake(18, sideButton.buttonImage.image.size.height * (18 / sideButton.buttonImage.image.size.height))];
        
//        if (!sideButton.buttonImage.image.isTemplate)
//            [sideButton.buttonImage.image setTemplate:true];
        
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            sideButton.hidden = false;
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = height;
            yLoc -= height;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
        } else {
            sideButton.hidden = true;
        }
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
    
    // Adjust text and background color
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSColor *primary = NSColor.darkGrayColor;
    NSColor *secondary = NSColor.blackColor;
    NSColor *highlight = NSColor.blackColor;
    if (_macOS >= 14) {
        if ([osxMode isEqualToString:@"Dark"]) {
            primary = NSColor.lightGrayColor;
            secondary = NSColor.whiteColor;
            highlight = NSColor.whiteColor;
        }
    }

    NSMutableArray *allButtons = _sidebarTopButtons.mutableCopy;
    [allButtons addObjectsFromArray:_sidebarBotButtons];
    for (MF_sidebarButton *sidebarButton in allButtons) {
        NSTextField *g = sidebarButton.buttonLabel;
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:g.stringValue];
        if (![sidebarButton isEqualTo:buttonContainer]) {
            [[sidebarButton layer] setBackgroundColor:[NSColor clearColor].CGColor];
            [colorTitle addAttribute:NSForegroundColorAttributeName value:primary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        } else {
            [[sidebarButton layer] setBackgroundColor:[highlight colorWithAlphaComponent:.25].CGColor];
            [colorTitle addAttribute:NSForegroundColorAttributeName value:secondary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        }
    }
}

- (void)setMainViewSubView:(NSView*)subview {
    NSScrollView *mv = (NSScrollView*)_mainView;
    
    MFFlippedView *documentView = [[MFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, mv.frame.size.width, subview.frame.size.height)];
    mv.documentView = documentView;

    [subview setFrameOrigin:CGPointZero];


    [subview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [subview setFrameSize:CGSizeMake(mv.frame.size.width, mv.frame.size.height - 2)];
    [documentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [documentView setFrameSize:CGSizeMake(mv.frame.size.width, mv.frame.size.height - 2)];

    [documentView setSubviews:@[subview]];
    [mv scrollPoint:CGPointZero];
    
//    [subview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
//    [subview setFrameSize:CGSizeMake(_mainView.frame.size.width, _mainView.frame.size.height)];
//    [_mainView setSubviews:@[subview]];
//    [_mainView scrollPoint:CGPointZero];
}

- (IBAction)selectPreference:(id)sender {
    NSView *selectedPane = [_preferenceViews objectAtIndex:[(NSSegmentedControl*)sender selectedSegment]];
    [_prefWindow setIsVisible:true];
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
    [NSApp activateIgnoringOtherApps:true];
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
    }
}

@end
