//
//  MF_Purchase.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_Purchase : NSObject

+ (void)pluginInstall:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo;
+ (void)pushthebutton:(MSPlugin*)plugin :(NSButton*)theButton :(NSString*)repo;
+ (void)checkStatus:(MSPlugin*)plugin :(NSButton*)theButton;

@end

NS_ASSUME_NONNULL_END
