//
//  MF_featuredItem.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredItemController.h"

#import "MF_bundleView.h"

extern AppDelegate *myDelegate;

@interface MF_featuredItemController ()

@end

@implementation MF_featuredItemController

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

- (void)setupWithPlugin:(MF_Plugin*)plugin {
    plug = plugin;
    self.bundleName.stringValue = plugin.webName;
    self.bundleDesc.stringValue = plugin.webDescriptionShort;
    self.bundleDescFull.stringValue = plugin.webDescription;
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
    
    self.bundlePreview.animates = YES;
    self.bundlePreview.canDrawSubviewsIntoLayer = YES;
    self.bundlePreview.wantsLayer = true;
//    self.bundlePreview.image = [NSImage imageNamed:NSImageNameBookmarksTemplate];
//    self.view.wantsLayer = true;
//    self.view.layer.backgroundColor = NSColor.redColor.CGColor;
    
    dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue0, ^{
        NSImage *icon = [MF_PluginManager pluginGetIcon:plugin.webPlist];
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
        NSString *repostring = @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo"; //@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo";
        NSString *imgurl = [NSString stringWithFormat:@"%@/documents/%@/icon.png", repostring, plugin.bundleID]; //[NSString stringWithFormat:@"%@%@", repostring, iconpath];
        NSString *preview = [NSString stringWithFormat:@"%@/documents/%@/previewImages/01.png", repostring, plugin.bundleID];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (iconpath) {
                self.bundleButton.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundleButton sd_setImageWithURL:[NSURL URLWithString:imgurl]
                                     placeholderImage:[UIImage imageNamed:NSImageNameApplicationIcon]];
            } else {
                self.bundleButton.image = icon;
            }
            
            if (preview) {
                self.bundlePreview.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
                [self.bundlePreview sd_setImageWithURL:[NSURL URLWithString:preview]
                                     placeholderImage:nil];
                
                self.bundlePreview.layer.backgroundColor = [NSColor colorWithRed:1 green:1 blue:1 alpha:0.6].CGColor;
                self.bundlePreview.layer.cornerRadius = 5;
            } else {
//                self.bundlePreview.image = nil;
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
