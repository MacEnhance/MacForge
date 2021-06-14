//
//  MF_featuredItem.m
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "MF_featuredItem.h"
#import "MF_Paddle.h"

extern AppDelegate *myDelegate;

@interface MF_featuredItem ()

@end

@implementation MF_featuredItem

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)getOrOpen:(id)sender {
    [MF_Purchase pushthebutton:plug :sender :MF_REPO_URL :_bundleProgress];
}

- (IBAction)moreInfo:(id)sender {
    MF_repoData.sharedInstance.currentPlugin = plug;
    plug.webRepository = MF_REPO_URL;
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [myDelegate.sidebarController setViewSubViewWithScrollableView:myDelegate.tabMain :myDelegate.sourcesBundle];
    });
}

- (void)setupWithPlugin:(MF_Plugin*)plugin {
    plug = plugin;
    
    _bundleName.stringValue = plugin.webName;
    _bundleDesc.stringValue = plugin.webDescriptionShort;
    _bundleDescFull.stringValue = plugin.webDescription;
    _bundleBanner.canDrawSubviewsIntoLayer = true;
    _bundleBanner.superview.wantsLayer = true;
    
    _bundleGet.backgroundNormalColor = NSColor.whiteColor;
    _bundleGet.backgroundHighlightColor = NSColor.whiteColor;
    _bundleGet.backgroundDisabledColor = NSColor.grayColor;
    if (@available(macOS 10.14, *)) {
        _bundleGet.titleNormalColor = NSColor.controlAccentColor;
    } else {
        _bundleGet.titleNormalColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
    }
    _bundleGet.titleHighlightColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
    _bundleGet.titleDisabledColor = NSColor.whiteColor;
    _bundleGet.cornerRadius = _bundleGet.frame.size.height/2;
    if (@available(macOS 10.15, *)) { _bundleGet.layer.cornerCurve = kCACornerCurveContinuous; }
    _bundleGet.spacing = 0.1;
    _bundleGet.borderWidth = 0;
    _bundleGet.momentary = true;
    _bundleGet.action = @selector(getOrOpen:);
    _bundleGet.target = self;
    
    _bundleBanner.action = @selector(moreInfo:);
    _bundleBanner.target = self;
    
    _bundlePreview.animates = true;
    _bundlePreview.wantsLayer = true;
    _bundlePreview.canDrawSubviewsIntoLayer = true;
    _bundlePreview.layer.cornerRadius = 5;
    if (@available(macOS 10.15, *)) { _bundlePreview.layer.cornerCurve = kCACornerCurveContinuous; }
    _bundlePreview.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
    _bundlePreview.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
    _bundlePreview.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    
    NSImage *icon = [MF_PluginManager pluginGetIcon:plugin.webPlist];
    NSDictionary *pluginPlist = plugin.webPlist;
    NSString *repostring = MF_REPO_URL;
    
    if (pluginPlist[@"icon"] || pluginPlist[@"customIcon"]) {
        _bundleIcon.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        [_bundleIcon sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/icon.png", repostring, plugin.bundleID]]
                             placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
    } else {
        _bundleIcon.image = icon;
    }
    
    NSString *banpath = pluginPlist[@"banner"];
    if (banpath && ![banpath.pathComponents.firstObject isEqualToString:@"https:"]) banpath = [NSString stringWithFormat:@"%@%@", MF_REPO_URL, banpath];
    if (!banpath.length) banpath = [NSString stringWithFormat:@"%@/documents/%@/previewImages/01.png", repostring, plugin.bundleID];
    if (banpath) {
        [_bundlePreview sd_setImageWithURL:[NSURL URLWithString:banpath] placeholderImage:nil];
    } else {
        _bundlePreview.image = nil;
    }
    
    if (plugin.webPaid) {
        if (plugin.paddleProduct) {
            NSLog(@"%@ : %hd", plugin.webName, plugin.paddleProduct.activated);
        } else {
            plugin.paddleProduct = [MF_Paddle productWithPlugin:plugin];
            NSLog(@"%@ : %hd", plugin.webName, plugin.paddleProduct.activated);
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (banpath.length) {
            NSImage *a = [NSImage.alloc initWithContentsOfURL:[NSURL URLWithString:banpath]];
            NSColor *newColor = [[SLColorArt.alloc initWithImage:a].backgroundColor colorWithAlphaComponent:0.5];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.bundlePreview.layer.backgroundColor = newColor.CGColor;
                
                // Scale image to fit if it's ratio won't cause much distortion
                float h = self.bundlePreview.frame.size.height / a.size.height;
                float w = self.bundlePreview.frame.size.width / a.size.width;
                float d = fabsf(h - w);
                if (d <= 0.25)
                    self.bundlePreview.imageScaling = NSImageScaleAxesIndependently;
            });
        }
        [MF_Purchase checkStatus:plugin :self.bundleGet];
    });
}

@end
