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
    
    // Drawing code here.
}

- (IBAction)goBack:(id)sender {
    [self performSelector:@selector(removeFromSuperview)];
}

@end
