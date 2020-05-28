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
    
    dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue0, ^{
        NSImage *icon = [MF_PluginManager pluginGetIcon:plugin.webPlist];
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
        NSString *banpath = [plugin.webPlist objectForKey:@"banner"];
        
        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@", iconpath];
        NSString *banurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@", banpath];
//        banurl = @"https://i.imgflip.com/2ect6i.gif";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (iconpath) {
                self.bundleButton.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
                self.bundleButton.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundleButton sd_setImageWithURL:[NSURL URLWithString:imgurl]
                                     placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
            } else {
                self.bundleButton.image = icon;
            }
            
            if (banpath) {
                self.bundleBanner.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
                self.bundleBanner.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundleBanner sd_setImageWithURL:[NSURL URLWithString:banurl]
                                     placeholderImage:nil];
            } else {
                self.bundleBanner.image = nil;
            }
        });
        
        [MF_Purchase checkStatus:plugin :self.bundleGet];
    });
}


- (IBAction)getOrOpen:(id)sender {
    [MF_Purchase pushthebutton:plug :sender :@"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo" :_bundleProgress];
}

- (IBAction)moreInfo:(id)sender {
    MF_repoData.sharedInstance.currentPlugin = plug;
    plug.webRepository = @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo";
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [myDelegate.sidebarController setViewSubViewWithScrollableView:myDelegate.tabMain :myDelegate.sourcesBundle];
    });
}


@end
