//
//  PreferenceLoaderProtocol.h
//  PreferenceLoader
//
//  Created by Jeremy on 5/25/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PreferenceLoaderProtocol

- (void)setPluginPath:(NSString *)path withReply:(void (^)(BOOL))reply;

@end
