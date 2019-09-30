//
//  MF_bundlePreviewView.h
//  MacForge
//
//  Created by Wolfgang Baird on 9/29/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;

@interface MF_bundlePreviewView : NSView

@property IBOutlet NSImageView*     bundlePreview;
@property IBOutlet NSButton*        bundlePreviewNext;
@property IBOutlet NSButton*        bundlePreviewPrev;
@property IBOutlet NSButton*        bundleBack;

@end

