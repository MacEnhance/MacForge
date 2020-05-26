//
//  MF_Purchase.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_Plugin.h"
#import <Foundation/Foundation.h>

@interface MF_Purchase : NSObject

+ (void)pluginInstall:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo;
+ (void)pushthebutton:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator* _Nullable)prog;
+ (void)checkStatus:(MF_Plugin*)plugin :(NSButton*)theButton;
+ (void)verifyPurchased:(MF_Plugin*)plugin :(NSButton*)theButton;

@end
