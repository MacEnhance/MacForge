//
//  MFKSipView.h
//  MacForgeKit
//
//  Created by Wolfgang Baird on 8/11/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AVFoundation;
@import AVKit;
@import AppKit;

@interface NoInteractPlayer : AVPlayerView
@end

@interface MFKSipView : NSViewController

@property IBOutlet NSTextField *tv;
@property IBOutlet NSButton *confirmQuit;
@property IBOutlet NSButton *confirmReboot;
@property IBOutlet NSButton *confirm;
@property IBOutlet NoInteractPlayer *NIPlayer;
@property IBOutlet AVPlayer *avp;

- (void)displayInWindow:(NSWindow*)window;

@end
