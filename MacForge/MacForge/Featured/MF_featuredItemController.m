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
//    self.bundleButton.image     = [PluginManager pluginGetIcon:plugin.webPlist];
    
    dispatch_queue_t backgroundQueue0 = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue0, ^{
        NSImage *icon = [PluginManager pluginGetIcon:plugin.webPlist];
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
//        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@?%@", iconpath, [[NSProcessInfo processInfo] globallyUniqueString]];
        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@", iconpath];

        if (iconpath)
            icon = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgurl]]];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bundleButton.image = icon;
        });
    });
    
    self.bundleBanner.animates = YES;
//    self.bundleBanner.image = [NSImage imageNamed:@"loading_mini.gif"];
    self.bundleBanner.canDrawSubviewsIntoLayer = YES;
    [self.bundleBanner.superview setWantsLayer:YES];
    self.bundleBanner.imageAlignment = NSImageAlignTop;
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue, ^{
        NSImage *sourceIcon = [[NSImage alloc] init];
//        NSURL* url1 = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgflip.com/2ect6i.gif?%@", [[NSProcessInfo processInfo] globallyUniqueString]]];
//        NSURL* url1 = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgflip.com/2ect6i.gif"]];
//        NSImage *icon = [[NSImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL: url1]];
//        sourceIcon = icon;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bundleBanner.image = sourceIcon;
        });
    });
    
    [MF_Purchase checkStatus:plugin :self.bundleGet];
//    self.bundleBanner.image     = [NSImage imageNamed:@"bg02"];
//    self.bundleGet = plugin.webName;
}


- (IBAction)getOrOpen:(id)sender {
    [MF_Purchase pushthebutton:plug :sender :@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo"];
}

- (IBAction)moreInfo:(id)sender {
//    NSLog(@"%@", plug.webPlist);
    NSLog(@"check");
}

@end
