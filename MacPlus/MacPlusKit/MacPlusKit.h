//
//  MacPlusKit.h
//  MacPlusKit
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

@import AppKit;

//! Project version number for MacPlusKit.
FOUNDATION_EXPORT double MacPlusKitVersionNumber;

//! Project version string for MacPlusKit.
FOUNDATION_EXPORT const unsigned char MacPlusKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MacPlusKit/PublicHeader.h>

@interface MacPlusKit : NSObject

+ (MacPlusKit *)sharedInstance;

+ (Boolean)AMFI_enabled;
+ (Boolean)AMFI_toggle;

+ (Boolean)SIP_enabled;

+ (Boolean)MacPlus_remove;

@end

