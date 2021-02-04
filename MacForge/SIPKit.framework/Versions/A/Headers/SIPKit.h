//
//  SIPKit.h
//  SIPKit
//
//  Created by Wolfgang Baird on 4/20/20.
//  Copyright © 2020 Wolfgang Baird. All rights reserved.
//

// In this header, you should import all the public headers of your framework
// using statements like #import <SIPKit/PublicHeader.h>

@import AppKit;
@import AVKit;
#import <ServiceManagement/ServiceManagement.h>

//! Project version number for SIPKit.
FOUNDATION_EXPORT double SIPKitVersionNumber;

//! Project version string for SIPKit.
FOUNDATION_EXPORT const unsigned char SIPKitVersionString[];

@interface SIPKit : NSObject

+ (void)getAuth;
+ (SIPKit*)kit;

// AMFI controls

/// Get rid of AMFI
+ (void)AMFI_NUKE;
/// 1 = enabled, 0 = disabled
+ (Boolean)AMFI_isEnabled;
/// 1 = success, 0 = fail
+ (Boolean)AMFI_amfi_allow_any_signature_toggle;
/// 1 = success, 0 = fail
+ (Boolean)AMFI_cs_enforcement_disable_toggle;
/// 1 = success, 0 = fail
+ (Boolean)AMFI_amfi_get_out_of_my_way_toggle;




// Warning windows

/// Set wether or not your app will show  AMFI warnings -- 1 = show, 0 = don't show
+ (void)AMFI_setShowAMFIWarning:(Boolean)shouldWarn;
/// Check if your app has set to hide AMFI warnings -- 1 = show, 0 = don't show
+ (Boolean)AMFI_shouldShowWarning;

/// Shows warning that handles all cases
+ (void)showMasterWaringinWindow:(NSWindow*)window reply:(void (^)(NSUInteger response))callback;
+ (void)showMasterWaringinWindow:(NSWindow*)window;

/// If a window is povided the warning will be shown as a sheet attached to the window otherwise it will be shown as it's own window
+ (void)AMFI_showWaringinWindow:(NSWindow*)window reply:(void (^)(NSUInteger response))callback;
+ (void)AMFI_showWaringinWindow:(NSWindow*)window;

/// Show a warning window as a sheet attached to `window`
+ (void)SIP_showWaringinWindow:(NSWindow*)window reply:(void (^)(NSUInteger response))callback;
+ (void)SIP_showWaringinWindow:(NSWindow*)window;

/// Show a warning window as a sheet attached to `window`
+ (void)ABI_showWaringinWindow:(NSWindow*)window reply:(void (^)(NSUInteger response))callback;
+ (void)ABI_showWaringinWindow:(NSWindow*)window;




// NVRAM

/// Check if an NVRAM arg is currently present -- 1 = arg present, 0 = arg missing
+ (Boolean)NVRAM_arg_present:(NSString*)arg;

/// Check if Library Validation is enabled -- 1 = enabled, 0 = disabled
+ (Boolean)LIBRARYVALIDATION_isEnabled;
/// Set Library Validation 1 = success, 0 = fail
+ (Boolean)LIBRARYVALIDATION_setEnabled:(BOOL)state;

/// Check if ABI is enabled -- 1 = enabled, 0 = disabled
+ (Boolean)ABI_isEnabled;
/// Set ABI 1 = success, 0 = fail
+ (Boolean)ABI_setEnabled:(BOOL)state;

/// Set system to reboot to recovery mode
+ (void)setRecoveryBoot;



// System Integrity Protection

/// Start the SIP disable process
+ (void)SIP_disableWithReboot:(Boolean)reboot;

/// Re-enable SIP
+ (void)SIP_enableWithReboot:(Boolean)reboot;

/// 1 = enabled, 0 = disabled
+ (Boolean)SIP_enabled;

/// 1 = has flags required for code injection, 0 = flags missing
+ (Boolean)SIP_HasRequiredFlags;

/// 1 = nvram flag enabled, 0 = disabled
+ (Boolean)SIP_NVRAM;

/// 1 = task for pid flag enabled, 0 = disabled
+ (Boolean)SIP_TASK_FOR_PID;

/// 1 = filesystem flag enabled, 0 = disabled
+ (Boolean)SIP_Filesystem;

@end
