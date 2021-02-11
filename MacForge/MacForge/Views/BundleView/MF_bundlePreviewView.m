//
//  MF_bundlePreviewView.m
//  MacForge
//
//  Created by Wolfgang Baird on 9/29/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_bundlePreviewView.h"

@implementation MF_bundlePreviewView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self.bundlePreview setWantsLayer:true];
    [self.bundlePreview setAnimates:true];
    // Drawing code here.
}

- (IBAction)goBack:(id)sender {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        [context setDuration:0.2];
        [[self animator] setFrameOrigin:NSMakePoint(self.frame.size.width, 0)];
    } completionHandler:^{
        [self removeFromSuperview];
    }];
}

- (IBAction)cyclePreviews:(id)sender {
    if (_bundlePreviewImages.count > 1) {
        NSInteger increment = -1;
        if ([sender isEqual:_bundlePreviewNext])
            increment = 1;
        
        NSInteger newPreview = _currentPreview += increment;
        if (increment == 1)
            if (newPreview >= _bundlePreviewImages.count)
                newPreview = 0;
        
        if (increment == -1)
            if (newPreview < 0)
                newPreview = _bundlePreviewImages.count - 1;
        
        _currentPreview = newPreview;
        self.bundlePreview.image = self.bundlePreviewImages[newPreview];
    }
}

@end
