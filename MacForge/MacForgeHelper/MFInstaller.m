//
//  MFInstaller.m
//  Dark
//
//  Created by Wolfgang Baird on 8/11/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "MFInstaller.h"
#import "MFFrameworkInstaller.h"

NSString *const MFInjectorExecutablLabel  = @"com.w0lf.MacForge.Injector";
NSString *const MFInstallerExecutablLabel = @"com.w0lf.MacForge.Installer";

@interface MFInstaller ()
+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error;
+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error;
+ (BOOL)installMachInjectBundleFramework:(NSError **)error;
@end

@implementation MFInstaller

+ (BOOL)isInstalled {
    NSString *versionInstalled = [[NSUserDefaults standardUserDefaults] stringForKey:MFUserDefaultsInstalledVersionKey];
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    BOOL result = false;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacForge.Injector"])
        return false;
    else
        result = true;
    
    if (result && ([currentVersion compare:versionInstalled] == NSOrderedSame))
        result = true;
    else
        result = false;
    
    if (![[NSFileManager defaultManager] isWritableFileAtPath:@"/Library/Application Support/MacEnhance/Plugins"])
        result = false;
    
    return result;
}

+ (BOOL)install:(NSError **)error {
    AuthorizationRef authRef = NULL;
    BOOL result = YES;

    result = [self askPermission:&authRef error:error];

    if (result == YES) {
        result = [self installHelperTool:MFInstallerExecutablLabel authorizationRef:authRef error:error];
    }

    if (result == YES) {
        result = [self installMachInjectBundleFramework:error];
    }
    
    if (result == YES) {
        result = [self setupPluginFolder:error];
    }

    if (result == YES) {
        result = [self installHelperTool:MFInjectorExecutablLabel authorizationRef:authRef error:error];
    }

    if (result == YES) {
        NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:MFUserDefaultsInstalledVersionKey];
        NSLog(@"Installed v%@", currentVersion);
    }
  
    return result;
}

+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error {
  // Creating auth item to bless helper tool and install framework
  AuthorizationItem authItem = {kSMRightBlessPrivilegedHelper, 0, NULL, 0};

  // Creating a set of authorization rights
	AuthorizationRights authRights = {1, &authItem};

  // Specifying authorization options for authorization
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;

  // Open dialog and prompt user for password
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, authRef);

  if (status == errAuthorizationSuccess) {
    return YES;
  } else {
    NSLog(@"%@ (error code: %@)", MFErrPermissionDeniedDescription, [NSNumber numberWithInt:status]);

    *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                        code:MFErrPermissionDenied
                                    userInfo:@{NSLocalizedDescriptionKey: MFErrPermissionDeniedDescription}];

    return NO;
  }
}

+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error {
  CFErrorRef blessError = NULL;
  BOOL result;

  result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)executableLabel, authRef, &blessError);
    
  if (result == NO) {
    CFIndex errorCode = CFErrorGetCode(blessError);
    CFStringRef errorDomain = CFErrorGetDomain(blessError);

    NSLog(@"an error occurred while installing %@ (domain: %@ (%@))", executableLabel, errorDomain, [NSNumber numberWithLong:errorCode]);

    *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                        code:MFErrInstallHelperTool
                                    userInfo:@{NSLocalizedDescriptionKey: MFErrInstallDescription}];
  } else {
    NSLog(@"Installed %@ successfully", executableLabel);
  }

  return result;
}

+ (BOOL)installMachInjectBundleFramework:(NSError **)error {
//  NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"mach_inject_bundle" ofType:@"framework"];
  NSString *frameworkPath = [NSString stringWithFormat:@"%@/Contents/Frameworks/mach_inject_bundle.framework", NSBundle.mainBundle.bundlePath];
  BOOL result = YES;

  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Installer.mach" host:nil];
//  assert(c != nil);

  MFFrameworkInstaller *installer = (MFFrameworkInstaller *)[c rootProxy];
//  assert(installer != nil);

  result = [installer installFramework:frameworkPath];

  if (result == YES) {
    NSLog(@"Installed mach_inject_bundle.framework successfully");
  } else {
    NSLog(@"an error occurred while installing mach_inject_bundle.framework (domain: %@ code: %@)", installer.error.domain, [NSNumber numberWithInteger:installer.error.code]);

    *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                        code:MFErrInstallFramework
                                    userInfo:@{NSLocalizedDescriptionKey: MFErrInstallDescription}];
  }

  return result;
}

+ (BOOL)setupPluginFolder:(NSError **)error {
    BOOL result = YES;
    
    NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacForge.Installer.mach" host:nil];
//    assert(c != nil);
    
    MFFrameworkInstaller *installer = (MFFrameworkInstaller *)[c rootProxy];
//    assert(installer != nil);
    
    result = [installer setupPluginFolder];
    
    if (result == YES) {
        NSLog(@"Setup plugins folder successfully");
    } else {
        NSLog(@"An error occurred while setting up plugins folder %@ %@", installer.error.domain, [NSNumber numberWithInteger:installer.error.code]);
        
        *error = [[NSError alloc] initWithDomain:MFErrorDomain
                                            code:MFErrInstallFramework
                                        userInfo:@{NSLocalizedDescriptionKey: MFErrInstallDescription}];
    }
    
    return result;
}

@end
