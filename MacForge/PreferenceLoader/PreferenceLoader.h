//
//  PreferenceLoader.h
//  PreferenceLoader
//
//  Created by Jeremy on 5/25/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferenceLoaderProtocol.h"
#import "ViewBridge.h"

@interface PreferenceLoader : NSObject <PreferenceLoaderProtocol>
@end

@interface PreferenceLoaderServiceView : NSServiceViewController
@end
