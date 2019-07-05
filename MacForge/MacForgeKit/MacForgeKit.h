//
//  MacForgeKit.h
//  MacForgeKit
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

@import AppKit;

//! Project version number for MacForgeKit.
FOUNDATION_EXPORT double MacForgeKitVersionNumber;

//! Project version string for MacForgeKit.
FOUNDATION_EXPORT const unsigned char MacForgeKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MacForgeKit/PublicHeader.h>

@interface MacForgeKit : NSObject

+ (MacForgeKit *)sharedInstance;
+ (Boolean)AMFI_enabled;
+ (Boolean)AMFI_toggle;
+ (Boolean)SIP_enabled;
+ (Boolean)MacPlus_remove;

@end

