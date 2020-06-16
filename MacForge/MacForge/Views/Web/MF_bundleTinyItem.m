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
    self.bundleName.stringValue = plugin.webName;
//    self.bundleDesc.stringValue = plugin.webDescription;
    self.bundleDesc.stringValue = plugin.webDescriptionShort;
    self.bundleDesc.toolTip = plugin.webDescriptionShort;
    self.bundleBanner.canDrawSubviewsIntoLayer = YES;
    [self.bundleBanner.superview setWantsLayer:YES];
    
    _bundleGet.backgroundNormalColor = NSColor.whiteColor;
    _bundleGet.backgroundHighlightColor = NSColor.whiteColor;
    _bundleGet.backgroundDisabledColor = NSColor.grayColor;
    _bundleGet.titleNormalColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
    _bundleGet.titleHighlightColor = [NSColor colorWithRed:0.4 green:0.6 blue:1 alpha:1];
    _bundleGet.titleDisabledColor = NSColor.whiteColor;
    _bundleGet.cornerRadius = _bundleGet.frame.size.height/2;
    _bundleGet.spacing = 0.1;
    _bundleGet.borderWidth = 0;
    _bundleGet.momentary = true;
    
    dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.macenhance.MacForge", 0);
    dispatch_async(backgroundQueue0, ^{
        NSString *banpath = [plugin.webPlist objectForKey:@"banner"];
        if (banpath && ![banpath.pathComponents.firstObject isEqualToString:@"https:"])
            banpath = [NSString stringWithFormat:@"%@%@", MF_REPO_URL, banpath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setwarning:self.bundleLIB :[[plugin.webPlist valueForKeyPath:@"system.LIB"] boolValue] :@"Library Validation"];
            [self setwarning:self.bundleSIP :[[plugin.webPlist valueForKeyPath:@"system.SIP"] boolValue] :@"System Integrity Protection"];
            
            if (plugin.webPlist[@"icon"] || plugin.webPlist[@"customIcon"]) {
                self.bundleButton.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundleButton sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/documents/%@/icon.png", MF_REPO_URL, plugin.bundleID]]
                                     placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
            } else {
                self.bundleButton.image = [MF_PluginManager pluginGetIcon:plugin.webPlist];
            }
            
            if (banpath) {
                self.bundleBanner.imageScaling = NSImageScaleAxesIndependently;
                self.bundleBanner.animates = true;
                self.bundleBanner.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
                self.bundleBanner.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundleBanner sd_setImageWithURL:[NSURL URLWithString:banpath]
                                     placeholderImage:nil];
            } else {
                self.bundleBanner.image = nil;
            }
        });
        
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
