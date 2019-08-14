//
//  MFKSipView.m
//  MacForgeKit
//
//  Created by Wolfgang Baird on 8/11/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MFKSipView.h"
#import "MacForgeKit.h"
@import AVKit;
@import AVFoundation;
@import AppKit;

@interface NoInteractPlayer : AVPlayerView
@end

@implementation NoInteractPlayer

- (void)scrollWheel:(NSEvent *)event {
    // Do nothing...
}

- (void)keyDown:(NSEvent *)event {
    // Do nothing...
}

@end

@implementation MFKSipView

//@synthesize confirm;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)awakeFromNib {
    //    [[self window] setBackgroundColor:[NSColor whiteColor]];
//    [[self window] setMovableByWindowBackground:true];
//    [[self window] setLevel:NSFloatingWindowLevel];
//    [[self window] setTitle:@""];
//    [[self confirm] setKeyEquivalentModifierMask:0];
//    [[self confirm] setKeyEquivalent:@"\r"];
    
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[self.view bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [self.view addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [self.view.layer setBackgroundColor:[NSColor whiteColor].CGColor];
        [self.view setWantsLayer:true];
    }
    
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    
    NSString *sipFile = @"eng_sip";
    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion > 13) sipFile = @"eng_sip_mojave";
    
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[MFKSipView class]]
                                                        URLForResource:sipFile withExtension:@"txt"]
                                              encoding:NSUTF8StringEncoding
                                                 error:&err];
    text = [text stringByReplacingOccurrencesOfString:@"<appname>" withString:app];
    [_tv setStringValue:text];
    
    NSURL* videoURL = [[NSBundle bundleForClass:[MacForgeKit class]] URLForResource:@"sipvid" withExtension:@"mp4"];
    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    //    player setresp
    
    NoInteractPlayer *playerView = [[NoInteractPlayer alloc] initWithFrame:CGRectMake(50, 70, 500, 250)];
    [self.view addSubview:playerView];
    [playerView setControlsStyle:AVPlayerViewControlsStyleNone];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    
    playerLayer.frame = playerView.bounds;
    [playerView.layer addSublayer:playerLayer];
    [player play];
}

- (void)addtoView:(NSView*)parentView {
//    NSView *t = self.window.contentView;
//    [t setFrameOrigin:NSMakePoint(
//                                  (NSWidth([parentView bounds]) - NSWidth([t frame])) / 2,
//                                  (NSHeight([parentView bounds]) - NSHeight([t frame])) / 2
//                                  )];
//    [t setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
//    [parentView addSubview:t];
//    [self close];
}

//+ (void)display:(NSWindow*)win {
//     
//}

- (void)displayInWindow:(NSWindow*)window {
//    NSWindow *simblWindow = self.window;
//    NSPoint childOrigin = window.frame.origin;
//    childOrigin.y += window.frame.size.height/2 - simblWindow.frame.size.height/2;
//    childOrigin.x += window.frame.size.width/2 - simblWindow.frame.size.width/2;
//    [window addChildWindow:simblWindow ordered:NSWindowAbove];
//    [simblWindow setFrameOrigin:childOrigin];
    
//    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(100, 100, 300, 300)];
//    NSView *view = self.view;
//    NSWindow *windowSheet = [[NSWindow alloc] initWithContentRect:[view frame] styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES];
//    [windowSheet setContentView:view];
//    [window beginSheet:windowSheet completionHandler:^(NSModalResponse returnCode) {
//
//    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:CMTimeMake(0, p.asset.duration.timescale)];
}

- (IBAction)reboot:(id)sender {
    NSLog(@"Robots");
    system("osascript -e 'tell application \"Finder\" to restart'");
}

- (IBAction)iconfirm:(id)sender {
//    self.view
    NSLog(@"Robots");
}

- (IBAction)confirmQuit:(id)sender {
    NSLog(@"Robots");
    [NSApp terminate:nil];
}

//- (void)windowDidLoad {
//    [super windowDidLoad];
//}

@end
