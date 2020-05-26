//
//  PreferenceLoader.m
//  PreferenceLoader
//
//  Created by Jeremy on 5/25/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "PreferenceLoader.h"
#import <objc/runtime.h>

NSString *pluginPath;

@implementation PreferenceLoader

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)setPluginPath:(NSString *)path withReply:(void (^)(BOOL))reply {
    pluginPath = path;
    reply(YES);
}

@end

@implementation PreferenceLoaderServiceView

- (instancetype)initWithNibName:(nullable NSNibName)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {

    NSBundle *prefBundle = [NSBundle bundleWithPath:pluginPath];
    [prefBundle load];
    self = [super initWithNibName:NSStringFromClass(prefBundle.principalClass) bundle:prefBundle];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    class_setSuperclass([[self class] superclass], prefBundle.principalClass);
    #pragma clang diagnostic pop
    return self;
}

@end
