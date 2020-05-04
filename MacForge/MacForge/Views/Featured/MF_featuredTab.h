//
//  MF_featuredTab.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import "MF_featuredSmallController.h"
#import "MF_featuredItemController.h"
#import "MF_bundleTinyItem.h"
#import <Foundation/Foundation.h>

@interface MF_featuredTab : NSView

@property NSMutableArray *smallArray;
@property NSMutableArray *largeArray;

-(void)showFeatured;
-(void)setFilter:(NSString*)filt;

@end

