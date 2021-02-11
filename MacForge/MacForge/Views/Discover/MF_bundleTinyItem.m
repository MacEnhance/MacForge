//
//  MF_bundleTinyItem.m
//  MacForge
//
//  Created by Wolfgang Baird on 2/8/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "MF_bundleTinyItem.h"

extern AppDelegate *myDelegate;

@interface MF_bundleTinyItem ()

@end

@implementation MF_bundleTinyItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSString * nibName = @"MF_bundleTinyItem";
    self = [super initWithNibName:nibName bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setwarning:(NSImageView*)v :(Boolean)required :(NSString*)toolTip {
    if (@available(macOS 10.14, *)) {
        NSImage *img = v.image;
        [img setTemplate:true];
        v.contentTintColor = NSColor.redColor;
        v.toolTip = [toolTip stringByAppendingString:@" must be disabled"];
        if (required) {
            v.contentTintColor = NSColor.greenColor;
            v.toolTip = [NSString.alloc initWithFormat:@"Works with %@ enabled", toolTip];
        }
    } else {
        v.hidden = true;
        // Fallback on earlier versions
    }
}

- (void)setupWithPlugin:(MF_Plugin*)plugin {
    plug = plugin;
    
    _bundleName.stringValue = plugin.webName;
    _bundleDesc.stringValue = plugin.webDescriptionShort;
    _bundleDesc.toolTip = plugin.webDescriptionShort;
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
    
    _bundleBackgroundButton.action = @selector(moreInfo:);
    _bundleBackgroundButton.target = self;
    
    NSDictionary *pluginPlist = plugin.webPlist;
    
    if (pluginPlist[@"icon"] || pluginPlist[@"customIcon"]) {
        self.bundleIcon.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        [self.bundleIcon sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/icon.png", MF_REPO_URL, plugin.bundleID]]
                             placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
    } else {
        self.bundleIcon.image = [MF_PluginManager pluginGetIcon:plugin.webPlist];
    }
    
    NSString *banpath = pluginPlist[@"banner"];
    if (banpath && ![banpath.pathComponents.firstObject isEqualToString:@"https:"])
        banpath = [NSString stringWithFormat:@"%@%@", MF_REPO_URL, banpath];
    if (banpath) {
        self.bundleBanner.imageScaling = NSImageScaleAxesIndependently;
        self.bundleBanner.animates = true;
        self.bundleBanner.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
        self.bundleBanner.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
        [self.bundleBanner sd_setImageWithURL:[NSURL URLWithString:banpath] placeholderImage:nil];
    } else {
        self.bundleBanner.image = nil;
    }
    
    dispatch_async(dispatch_queue_create("com.macenhance.MacForge", 0), ^{
        [MF_Purchase checkStatus:plugin :self.bundleGet];
    });
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

@end
