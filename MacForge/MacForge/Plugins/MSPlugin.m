//
//  MSPlugin.m
//  MacPlus
//
//  Created by Wolfgang Baird on 6/22/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

#import "MSPlugin.h"

@implementation MSPlugin

+ (MSPlugin*) sharedInstance
{
    static MSPlugin* msP = nil;
    
    if (msP == nil)
        msP = [[MSPlugin alloc] init];
    
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
