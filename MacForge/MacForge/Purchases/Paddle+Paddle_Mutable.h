//
//  Paddle+Paddle_Mutable.h
//  MacForge
//
//  Created by Jeremy on 11/19/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import <Paddle/Paddle.h>

NS_ASSUME_NONNULL_BEGIN

@interface Paddle (Paddle_Mutable)

+ (nullable instancetype)newSharedInstanceWithVendorID:(nonnull NSString *)vendorID
                                                apiKey:(nonnull NSString *)apiKey
                                             productID:(nonnull NSString *)productID
                                         configuration:(nonnull PADProductConfiguration *)configuration
                                              delegate:(nullable id<PaddleDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
