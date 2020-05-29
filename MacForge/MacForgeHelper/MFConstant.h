//
//  MFError.h
//  Dark
//
//  Created by Wolfgang Baird on 8/11/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

FOUNDATION_EXPORT NSString *const MFUserDefaultsInstalledVersionKey;
FOUNDATION_EXPORT NSString *const MFErrorDomain;

enum {
  MFErrPermissionDenied  = 0,
  MFErrInstallHelperTool = 1,
  MFErrInstallFramework  = 2,
  MFErrInjection         = 3,
};

FOUNDATION_EXPORT NSString *const MFErrPermissionDeniedDescription;
FOUNDATION_EXPORT NSString *const MFErrInstallDescription;
FOUNDATION_EXPORT NSString *const MFErrInjectionDescription;
