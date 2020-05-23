//
//  MF_Plugin.m
//  MacForge
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

#import "MF_Plugin.h"

@implementation MF_Plugin

+ (MF_Plugin*) sharedInstance
{
    static MF_Plugin* msP = nil;
    
    if (msP == nil)
        msP = [[MF_Plugin alloc] init];
    
    return msP;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _localName = @"Test";
        _bundleID = @"com.w0lf.test";
    }
    return self;
}
    
@end
