//
//  MF_Purchase.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_Plugin.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_Purchase : NSObject

+ (void)pluginInstall:(MF_Plugin*)plugin withButton:(NSButton*)theButton andProgress:(NSProgressIndicator*)progress;
+ (void)pushthebutton:(MF_Plugin*)plugin :(NSButton*)theButton :(NSString*)repo :(NSProgressIndicator* _Nullable)prog;
+ (void)checkStatus:(MF_Plugin*)plugin :(NSButton*)theButton;

@end

NS_ASSUME_NONNULL_END
