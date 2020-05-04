//
//  MF_sidebarButton.h
//  MacForge
//
//  Created by Wolfgang Baird on 4/30/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_sidebarButton : NSView

@property IBOutlet NSImageView*     buttonImage;
@property IBOutlet NSButton*        buttonClickArea;
@property IBOutlet NSTextField*     buttonLabel;
@property IBOutlet NSView*          linkedView;

@end
