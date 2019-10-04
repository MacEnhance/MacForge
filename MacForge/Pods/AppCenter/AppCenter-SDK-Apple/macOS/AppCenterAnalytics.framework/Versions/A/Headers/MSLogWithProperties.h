// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <Foundation/Foundation.h>

#import "MSAbstractLog.h"

@interface MSLogWithProperties : MSAbstractLog

/**
 * Additional key/value pair parameters. [optional]
 */
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *properties;

@end
