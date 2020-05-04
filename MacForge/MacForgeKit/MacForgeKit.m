//
//  MacForgeKit.m
//  MacForgeKit
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

#import "STPrivilegedTask.h"
#import "MacForgeKit.h"
#import "SIMBL.h"

//  SYSTEM INTEGRITY PROTECTION RELATED
//  https://github.com/JayBrown/csrstat-NG

typedef uint32_t csr_config_t;
csr_config_t config = 0;

/* Rootless configuration flags */
#define CSR_ALLOW_UNTRUSTED_KEXTS               (1 << 0)    // 1
#define CSR_ALLOW_UNRESTRICTED_FS               (1 << 1)    // 2
#define CSR_ALLOW_TASK_FOR_PID                  (1 << 2)    // 4
#define CSR_ALLOW_KERNEL_DEBUGGER               (1 << 3)    // 8
#define CSR_ALLOW_APPLE_INTERNAL                (1 << 4)    // 16
#define CSR_ALLOW_UNRESTRICTED_DTRACE           (1 << 5)    // 32
#define CSR_ALLOW_UNRESTRICTED_NVRAM            (1 << 6)    // 64
#define CSR_ALLOW_DEVICE_CONFIGURATION          (1 << 7)    // 128
#define CSR_ALLOW_ANY_RECOVERY_OS               (1 << 8)    // 256
#define CSR_ALLOW_UNAPPROVED_KEXTS              (1 << 9)    // 512
#define CSR_ALLOW_EXECUTABLE_POLICY_OVERRIDE    (1 << 10)   // 1024

#define CSR_VALID_FLAGS (CSR_ALLOW_UNTRUSTED_KEXTS | \
    CSR_ALLOW_UNRESTRICTED_FS | \
    CSR_ALLOW_TASK_FOR_PID | \
    CSR_ALLOW_KERNEL_DEBUGGER | \
    CSR_ALLOW_APPLE_INTERNAL | \
    CSR_ALLOW_UNRESTRICTED_DTRACE | \
    CSR_ALLOW_UNRESTRICTED_NVRAM  | \
    CSR_ALLOW_DEVICE_CONFIGURATION | \
    CSR_ALLOW_ANY_RECOVERY_OS | \
    CSR_ALLOW_UNAPPROVED_KEXTS | \
    CSR_ALLOW_EXECUTABLE_POLICY_OVERRIDE)

extern int csr_check(csr_config_t mask) __attribute__((weak_import));
extern int csr_get_active_config(csr_config_t* config) __attribute__((weak_import));

bool _csr_check(int aMask, bool aFlipflag) {
    if (!csr_check)
        return (aFlipflag) ? 0 : 1; // return "UNRESTRICTED" when on old macOS version
    bool bit = (config & aMask);
    return bit;
}

// END SYSTEM INTEGRITY PROTECTION RELATED

@implementation MacForgeKit

NSString *const MFAMFIWarningKey = @"MF_AMFIShowWarning";

+ (MacForgeKit*) sharedInstance {
    static MacForgeKit* MacForge = nil;
    if (MacForge == nil)
        MacForge = [[MacForgeKit alloc] init];
    return MacForge;
}

+ (Boolean)runSTPrivilegedTask:(NSString*)launchPath :(NSArray*)args {
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    NSMutableArray *components = [args mutableCopy];
    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:components];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    Boolean result = false;
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
        }
    } else {
        result = true;
    }
    return result;
}

+ (NSString*)runScript:(NSString*)script {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", script];
    task.standardOutput = pipe;
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}


/* ------------------ SIP ------------------ */

+ (Boolean)SIP_enabled {
    csr_get_active_config(&config);
    // SIP fully disabled
    if (!_csr_check(CSR_ALLOW_APPLE_INTERNAL, 0) &&
        _csr_check(CSR_ALLOW_UNTRUSTED_KEXTS, 1) &&
        _csr_check(CSR_ALLOW_TASK_FOR_PID, 1) &&
        _csr_check(CSR_ALLOW_UNRESTRICTED_FS, 1) &&
        _csr_check(CSR_ALLOW_UNRESTRICTED_NVRAM, 1) &&
        !_csr_check(CSR_ALLOW_DEVICE_CONFIGURATION, 0)) {
        return false;
    }
    // SIP is at least partially or fully enabled
    return true;
}

+ (Boolean)SIP_HasRequiredFlags {
    csr_get_active_config(&config);
    // These are the two flags required for code injection to work
    return (_csr_check(CSR_ALLOW_UNRESTRICTED_FS, 1) && _csr_check(CSR_ALLOW_TASK_FOR_PID, 1));
}

+ (Boolean)SIP_NVRAM {
    csr_get_active_config(&config);
    BOOL allowsNVRAM = _csr_check(CSR_ALLOW_UNRESTRICTED_NVRAM, 1);
    return !allowsNVRAM;
}

+ (Boolean)SIP_TASK_FOR_PID {
    csr_get_active_config(&config);
    BOOL allowsTFPID = _csr_check(CSR_ALLOW_TASK_FOR_PID, 1);
    return !allowsTFPID;
}

+ (Boolean)SIP_Filesystem {
    csr_get_active_config(&config);
    BOOL allowsFS = _csr_check(CSR_ALLOW_UNRESTRICTED_FS, 1);
    return !allowsFS;
}

/* ------------------ Library Validation ------------------ */

+ (void)showAMFIWarning:(NSWindow*)inWindow {
    NSError *err;
    NSString *app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (app == nil) app = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (app == nil) app = @"macOS Plugin Framework";
    NSString *sipFile = @"amfi";
    NSString *text = [NSString stringWithContentsOfURL:[[NSBundle bundleForClass:[self class]]
                                                        URLForResource:sipFile withExtension:@"txt"]
                                              encoding:NSUTF8StringEncoding
                                                 error:&err];
    
    text = [text stringByReplacingOccurrencesOfString:@"<appname>" withString:app];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Apple Mobile File Integrity Warning!"];
    [alert setInformativeText:text];
    [alert addButtonWithTitle:@"Okay"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert setShowsSuppressionButton:true];
    alert.suppressionButton.title = @"Don't show this again";

    if (inWindow != nil) {
        [alert beginSheetModalForWindow:inWindow completionHandler:^(NSModalResponse returnCode) {
            if (alert.suppressionButton.state == NSOnState) [MacForgeKit setShowAMFIWarning:false];
            if (returnCode == NSAlertSecondButtonReturn) {
                return;
            } else {
                [MacForgeKit AMFI_NUKE_NOCHECK];
            }
        }];
    } else {
        NSModalResponse res = alert.runModal;
        if (alert.suppressionButton.state == NSOnState) [MacForgeKit setShowAMFIWarning:false];
        if (res == NSAlertSecondButtonReturn) {
            return;
        } else {
            [MacForgeKit AMFI_NUKE_NOCHECK];
        }
    }
}

+ (Boolean)shouldWarnAboutAMFI {
    Boolean result = true;
//    if ([MacForgeKit AMFI_enabled]) result = false;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d valueForKey:MFAMFIWarningKey])
        result = [[d valueForKey:MFAMFIWarningKey] boolValue];
    return result;
}

+ (void)setShowAMFIWarning:(Boolean)suppress {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:suppress] forKey:MFAMFIWarningKey];
}

+ (void)AMFI_NUKE_NOCHECK {
    AuthorizationRef authorizationRef;
    OSStatus status;
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    
    [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/usr/sbin/nvram"
                                                 arguments:@[@"-d", @"boot-args"]
                                          currentDirectory:[[NSBundle mainBundle] resourcePath]
                                             authorization:authorizationRef];
    
    [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/usr/bin/defaults"
                                                 arguments:@[@"write", @"/Library/Preferences/com.apple.security.libraryvalidation.plist", @"DisableLibraryValidation", @"-bool", @"true"]
                                          currentDirectory:[[NSBundle mainBundle] resourcePath]
                                             authorization:authorizationRef];
}

+ (void)AMFI_NUKE {
    NSString *result = [MacForgeKit runScript:@"nvram boot-args 2>&1"];
    if ([result containsString:@"amfi_get_out_of_my_way"]) {
        AuthorizationRef authorizationRef;
        OSStatus status;
        status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
        
        [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/usr/sbin/nvram"
                                                     arguments:@[@"-d", @"boot-args"]
                                              currentDirectory:[[NSBundle mainBundle] resourcePath]
                                                 authorization:authorizationRef];
        
        [STPrivilegedTask launchedPrivilegedTaskWithLaunchPath:@"/usr/bin/defaults"
                                                     arguments:@[@"write", @"/Library/Preferences/com.apple.security.libraryvalidation.plist", @"DisableLibraryValidation", @"-bool", @"true"]
                                              currentDirectory:[[NSBundle mainBundle] resourcePath]
                                                 authorization:authorizationRef];
    }
}

+ (Boolean)LIBRARYVALIDATION_enabled {
    NSString *result = [MacForgeKit runScript:@"defaults read /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation"];
    return !([result rangeOfString:@"1"].length);
}

+ (Boolean)LIBRARYVALIDATION_toggle {
//    sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
    NSString *newBootArgs = [MacForgeKit runScript:@"defaults read /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation"];
    if ([newBootArgs containsString:@"0"] || newBootArgs == nil) {
        newBootArgs = @"true";
    } else {
        newBootArgs = @"false";
    }
    [MacForgeKit runSTPrivilegedTask:@"/usr/bin/defaults" :@[@"write", @"/Library/Preferences/com.apple.security.libraryvalidation.plist", @"DisableLibraryValidation", @"-bool", newBootArgs]];
    NSString *result = [MacForgeKit runScript:@"defaults read /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation"];
    return ![result isEqualToString:newBootArgs];
}

/* ------------------ AMFI ------------------ */

// Note:
// cs_enforcement_disable=1
// amfi_get_out_of_my_way=1

+ (Boolean)AMFI_enabled {
    NSString *result = [MacForgeKit runScript:@"nvram boot-args 2>&1"];
    return !([result rangeOfString:@"amfi_get_out_of_my_way=1"].length);
}

+ (Boolean)NVRAM_arg_present:(NSString*)arg {
    NSString *result = [MacForgeKit runScript:@"nvram boot-args 2>&1"];
    return [result rangeOfString:arg].length;
}

+ (Boolean)toggleBootArg:(NSString*)arg {
    NSString *newBootArgs = [MacForgeKit runScript:@"nvram boot-args"];
    NSString *argEnabled = [arg stringByAppendingString:@"=1"];
    
    
    // Remove cs_enforcement_disable=1
    if ([newBootArgs containsString:argEnabled]) {
        newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString:argEnabled withString:@""];
    } else {
    // Add cs_enforcement_disable=1
        newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        newBootArgs = [newBootArgs stringByAppendingFormat:@" %@", argEnabled];
    }
    
    newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString:@"boot-args" withString:@""];
    newBootArgs = [newBootArgs stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    newBootArgs = [newBootArgs stringByReplacingOccurrencesOfString: @"[ \t]+"
                                                         withString: @" "
                                                            options: NSRegularExpressionSearch
                                                              range: NSMakeRange(0, newBootArgs.length)];
    
    newBootArgs = [NSString stringWithFormat:@"boot-args=%@", newBootArgs];
    [MacForgeKit runSTPrivilegedTask:@"/usr/sbin/nvram" :@[newBootArgs]];
    return !([newBootArgs rangeOfString:argEnabled].length);
}

+ (Boolean)AMFI_amfi_allow_any_signature_toggle {
    return [MacForgeKit toggleBootArg:@"amfi_allow_any_signature"];
}

+ (Boolean)AMFI_cs_enforcement_disable_toggle {
    return [MacForgeKit toggleBootArg:@"cs_enforcement_disable"];
}

+ (Boolean)AMFI_amfi_get_out_of_my_way_toggle {
    return [MacForgeKit toggleBootArg:@"amfi_get_out_of_my_way"];
}

/* ------------------ Extra ------------------ */

+ (Boolean)MacEnhance_remove {
    NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[MacForgeKit class]] pathForResource:@"cleanup" ofType:nil]];
    return [MacForgeKit runSTPrivilegedTask:@"/bin/sh" :args];
}

@end
