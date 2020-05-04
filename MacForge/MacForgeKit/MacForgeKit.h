//
//  MacForgeKit.h
//  MacForgeKit
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

@import AppKit;
#import "MFKSipView.h"

//! Project version number for MacForgeKit.
FOUNDATION_EXPORT double MacForgeKitVersionNumber;

//! Project version string for MacForgeKit.
FOUNDATION_EXPORT const unsigned char MacForgeKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MacForgeKit/PublicHeader.h>

@interface MacForgeKit : NSObject

+ (MacForgeKit *)sharedInstance;

+ (void)AMFI_NUKE;
+ (Boolean)AMFI_enabled;
+ (Boolean)AMFI_amfi_allow_any_signature_toggle;
+ (Boolean)AMFI_cs_enforcement_disable_toggle;
+ (Boolean)AMFI_amfi_get_out_of_my_way_toggle;

+ (Boolean)shouldWarnAboutAMFI;
+ (void)showAMFIWarning:(NSWindow*)inWindow;
+ (void)setShowAMFIWarning:(Boolean)shouldWarn;

+ (Boolean)NVRAM_arg_present:(NSString*)arg;

+ (Boolean)LIBRARYVALIDATION_enabled;
+ (Boolean)LIBRARYVALIDATION_toggle;

+ (Boolean)SIP_enabled;
+ (Boolean)SIP_HasRequiredFlags;
+ (Boolean)SIP_NVRAM;
+ (Boolean)SIP_TASK_FOR_PID;
+ (Boolean)SIP_Filesystem;

+ (Boolean)MacEnhance_remove;

@end

