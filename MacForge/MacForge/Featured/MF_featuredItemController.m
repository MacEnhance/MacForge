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
    self.bundleName.stringValue = plugin.webName;
    self.bundleDesc.stringValue = plugin.webDescription;
    self.bundleButton.image     = [PluginManager pluginGetIcon:plugin.webPlist];
    self.bundleBanner.image     = [NSImage imageNamed:@"bg01"];
//    self.bundleGet = plugin.webName;
}


- (IBAction)changeText:(id)sender {
    NSLog(@"Hello");
}


@end
