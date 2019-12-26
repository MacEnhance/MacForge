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

// Note:
//
// cs_enforcement_disable=1
// amfi_get_out_of_my_way=1
//

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

+ (Boolean)MacEnhance_remove {
    NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[MacForgeKit class]] pathForResource:@"cleanup" ofType:nil]];
    return [MacForgeKit runSTPrivilegedTask:@"/bin/sh" :args];
}

+ (void)startWatching {
    NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification * _Nonnull note) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        NSRunningApplication *app = [note.userInfo valueForKey:NSWorkspaceApplicationKey];
                                        [MacForgeKit injectBundle:app];
                                    });
                                }];
}

// Check if a bundle should be injected into specified running application
+ (Boolean)shouldInject:(NSRunningApplication*)runningApp {
    // Abort if you're running something other than macOS 10.X.X
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", NSProcessInfo.processInfo.operatingSystemVersion.majorVersion);
        return false;
    }
    
    // Don't inject into ourself
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:runningApp.bundleIdentifier]) return false;
    
    // Hardcoded blacklist
    if ([@[@"com.w0lf.MacForge", @"com.w0lf.MacForgeHelper", @"com.macenhance.purchaseValidationApp", @"com.apple.AccountProfileRemoteViewService"] containsObject:runningApp.bundleIdentifier]) return false;

    // Don't inject if somehow the executable doesn't seem to exist
    if (!runningApp.executableURL.path.length) return false;
    
    // If you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    // Log some info about the app
    NSString* appName = runningApp.localizedName;
    SIMBLLogInfo(@"%@ started", appName);
    SIMBLLogDebug(@"app start notification: %@", runningApp);
    
    // Check to see if there are plugins to load
    if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return false;
    
    // User Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil && [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return false;
    }
    
    // System item Inject
    if (runningApp.executableURL.path.pathComponents > 0)
        if ([runningApp.executableURL.path.pathComponents[1] isEqualToString:@"System"]) SIMBLLogDebug(@"injecting into system process");
    
    return true;
}

// Try injecting all valid bundles into an running application
+ (void)injectBundle:(NSRunningApplication*)runningApp {
    // Check if there is anything valid to inject
    if ([MacForgeKit shouldInject:runningApp]) {
        // See if MacForge is insatlled and if so open it and try to inject
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        NSString *mpHelper = [workspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacForgeHelper"];
        NSURL *mpURL = [NSURL URLWithString:mpHelper];
        NSArray *args = @[@"-i", runningApp.bundleIdentifier];
        NSError *error = nil;
        [workspace launchApplicationAtURL:mpURL
                                  options:0
                            configuration:[NSDictionary dictionaryWithObject:args forKey:NSWorkspaceLaunchConfigurationArguments]
                                    error:&error];
    }
}

+ (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [MacForgeKit injectBundle:app];
}

@end
