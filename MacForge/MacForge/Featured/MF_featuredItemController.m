//
//  MF_featuredItem.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredItemController.h"

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

- (void)setupWithPlugin:(MSPlugin*)plugin {
    plug = plugin;
    self.bundleName.stringValue = plugin.webName;
    self.bundleDesc.stringValue = plugin.webDescription;
    self.bundleBanner.animates = YES;
    self.bundleBanner.canDrawSubviewsIntoLayer = YES;
    [self.bundleBanner.superview setWantsLayer:YES];
    
    dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue0, ^{
        NSImage *icon = [PluginManager pluginGetIcon:plugin.webPlist];
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
        NSString *banpath = [plugin.webPlist objectForKey:@"banner"];

        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@", iconpath];
        NSString *banurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@", banpath];
        
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
    });
    
    [MF_Purchase checkStatus:plugin :self.bundleGet];
}


- (IBAction)getOrOpen:(id)sender {
    [MF_Purchase pushthebutton:plug :sender :@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo"];
}

- (IBAction)moreInfo:(id)sender {
//    NSLog(@"%@", plug.webPlist);
    NSLog(@"check");
}

@end
