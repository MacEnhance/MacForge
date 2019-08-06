//
//  MF_featuredSmallController.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredSmallController.h"

@interface MF_featuredSmallController ()

@end

@implementation MF_featuredSmallController

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
        NSDate *startTime = [NSDate date];

        NSImage *icon = [PluginManager pluginGetIcon:plugin.webPlist];
        NSString *iconpath = [plugin.webPlist objectForKey:@"icon"];
        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo%@?%@", iconpath, [[NSProcessInfo processInfo] globallyUniqueString]];
        if (iconpath)
            icon = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgurl]]];
        
//        NSImage *icon = [PluginManager pluginGetIcon:plugin.webPlist];
//        NSString *bundleID = [plugin.webPlist objectForKey:@"package"];
//        NSString *imgurl = [NSString stringWithFormat:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo/images/%@/icon.png?%@", bundleID, [[NSProcessInfo processInfo] globallyUniqueString]];
////        NSURL *myURL = [NSURL URLWithString:imgurl];
////        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: myURL];
////        [request setHTTPMethod: @"HEAD"];
////        NSURLResponse *response;
////        NSError *error;
////        NSData *myData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//
//
//        NSURL *myURL = [NSURL URLWithString:imgurl];
//        NSURLRequest *request = [NSMutableURLRequest requestWithURL: myURL];
//        NSURLResponse *response;
//        NSError *error;
//        NSData *data=[[NSData alloc] initWithData:[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]];
////        NSString* retVal = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        // you can use retVal , ignore if you don't need.
//        NSInteger httpStatus = [((NSHTTPURLResponse *)response) statusCode];
////        NSLog(@"responsecode: %ld", (long)httpStatus);
//        // there will be various HTTP response code (status)
//        // you might concern with 404
//        if (httpStatus != 404) {
//            icon = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imgurl]]];
//            // do your job
//        }
        
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
        NSLog(@"%@ execution time : %f Seconds", @"", executionTime);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bundleButton.image = icon;
        });
    });
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue, ^{
        NSImage *sourceIcon = [[NSImage alloc] init];
//        NSURL* url1 = [NSURL URLWithString:[NSString stringWithFormat:@"https://i.imgflip.com/2ect6i.gif?%@", [[NSProcessInfo processInfo] globallyUniqueString]]];
//        NSImage *icon = [[NSImage alloc] initWithData:[[NSData alloc] initWithContentsOfURL: url1]];
//        sourceIcon = icon;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bundleBanner.image = sourceIcon;
        });
    });
    
    self.bundleBanner.animates = YES;
    self.bundleBanner.canDrawSubviewsIntoLayer = YES;
    [self.bundleBanner.superview setWantsLayer:YES];
    self.bundleBanner.imageAlignment = NSImageAlignTop;
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
