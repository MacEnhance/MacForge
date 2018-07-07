//
//  DKError.h
//  Dark
//
//  Created by Erwan Barrier on 8/11/12.
//  Copyright (c) 2012 Erwan Barrier. All rights reserved.
//

FOUNDATION_EXPORT NSString *const DKUserDefaultsInstalledVersionKey;

FOUNDATION_EXPORT NSString *const DKErrorDomain;

enum {
  DKErrPermissionDenied  = 0,
  DKErrInstallHelperTool = 1,
  DKErrInstallFramework  = 2,
  DKErrInjection         = 3,
};

FOUNDATION_EXPORT NSString *const DKErrPermissionDeniedDescription;
FOUNDATION_EXPORT NSString *const DKErrInstallDescription;
FOUNDATION_EXPORT NSString *const DKErrInjectionDescription;
