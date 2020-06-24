//
//  MF_Purchase.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/5/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import Paddle;

#import "MF_Plugin.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_Paddle : NSObject
+ (instancetype)sharedInstance;
+ (void)validadePlugin:(MF_Plugin*)plugin withButton:(NSButton*)theButton;
+ (void)purchasePlugin:(MF_Plugin*)plugin withButton:(NSButton*)theButton andProgress:(NSProgressIndicator*)progress;
@end

NS_ASSUME_NONNULL_END
