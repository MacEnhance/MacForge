//
//  DKInstaller.m
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

#import <ServiceManagement/ServiceManagement.h>

#import "DKInstaller.h"
#import "DKFrameworkInstaller.h"

NSString *const DKInjectorExecutablLabel  = @"com.w0lf.MacPlus.Injector";
NSString *const DKInstallerExecutablLabel = @"com.w0lf.MacPlus.Installer";

@interface DKInstaller ()
+ (BOOL)askPermission:(AuthorizationRef *)authRef error:(NSError **)error;
+ (BOOL)installHelperTool:(NSString *)executableLabel authorizationRef:(AuthorizationRef)authRef error:(NSError **)error;
+ (BOOL)installMachInjectBundleFramework:(NSError **)error;
@end

@implementation DKInstaller

+ (BOOL)isInstalled {
  NSString *versionInstalled = [[NSUserDefaults standardUserDefaults] stringForKey:DKUserDefaultsInstalledVersionKey];
  NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  return ([currentVersion compare:versionInstalled] == NSOrderedSame);
}

+ (BOOL)install:(NSError **)error {
  AuthorizationRef authRef = NULL;
  BOOL result = YES;

  result = [self askPermission:&authRef error:error];

  if (result == YES) {
    result = [self installHelperTool:DKInstallerExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
    result = [self installMachInjectBundleFramework:error];
  }

  if (result == YES) {
    result = [self installHelperTool:DKInjectorExecutablLabel authorizationRef:authRef error:error];
  }

  if (result == YES) {
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:DKUserDefaultsInstalledVersionKey];

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
    NSLog(@"%@ (error code: %@)", DKErrPermissionDeniedDescription, [NSNumber numberWithInt:status]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrPermissionDenied
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrPermissionDeniedDescription}];

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

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInstallHelperTool
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInstallDescription}];
  } else {
    NSLog(@"Installed %@ successfully", executableLabel);
  }

  return result;
}

+ (BOOL)installMachInjectBundleFramework:(NSError **)error {
  NSString *frameworkPath = [[NSBundle mainBundle] pathForResource:@"mach_inject_bundle" ofType:@"framework"];
  BOOL result = YES;

  NSConnection *c = [NSConnection connectionWithRegisteredName:@"com.w0lf.MacPlus.Installer.mach" host:nil];
  assert(c != nil);

  DKFrameworkInstaller *installer = (DKFrameworkInstaller *)[c rootProxy];
  assert(installer != nil);

  result = [installer installFramework:frameworkPath];

  if (result == YES) {
    NSLog(@"Installed mach_inject_bundle.framework successfully");
  } else {
    NSLog(@"an error occurred while installing mach_inject_bundle.framework (domain: %@ code: %@)", installer.error.domain, [NSNumber numberWithInteger:installer.error.code]);

    *error = [[NSError alloc] initWithDomain:DKErrorDomain
                                        code:DKErrInstallFramework
                                    userInfo:@{NSLocalizedDescriptionKey: DKErrInstallDescription}];
  }

  return result;
}

@end
