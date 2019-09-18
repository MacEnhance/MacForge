//
//  MF_featuredTab.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredSmallController.h"
#import "MF_featuredItemController.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredTab : NSView

@property MF_featuredItemController *largeFeature01;
@property MF_featuredItemController *largeFeature02;

@property MF_featuredSmallController *smallFeature01;
@property MF_featuredSmallController *smallFeature02;
@property MF_featuredSmallController *smallFeature03;
@property MF_featuredSmallController *smallFeature04;
@property MF_featuredSmallController *smallFeature05;
@property MF_featuredSmallController *smallFeature06;

@property MF_featuredSmallController *smallFeature;

@end

NS_ASSUME_NONNULL_END
