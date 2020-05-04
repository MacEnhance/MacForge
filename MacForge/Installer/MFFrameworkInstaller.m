//
//  MFInstaller.m
//  MFInstaller
//
//  Created by Wolfgang Baird on 8/11/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import "MFFrameworkInstaller.h"

NSString *const MFFrameworkDstPath = @"/Library/Frameworks/mach_inject_bundle.framework";

@implementation MFFrameworkInstaller

@synthesize error = _error;

- (BOOL)installFramework:(NSString *)frameworkPath {
  // Disarm timer while installing framework
  dispatch_source_set_timer(g_timer_source, DISPATCH_TIME_FOREVER, 0llu, 0llu);

  NSError *fileError;
  BOOL result = YES;

  if ([[NSFileManager defaultManager] fileExistsAtPath:MFFrameworkDstPath] == YES) {
    result = [[NSFileManager defaultManager] removeItemAtPath:MFFrameworkDstPath error:&fileError];
  }

  if (result == YES) {
    result = [[NSFileManager defaultManager] copyItemAtPath:frameworkPath toPath:MFFrameworkDstPath error:&fileError];
  }

  if (result == NO) {
    _error = fileError;
  }
  
  // Rearm timer
  dispatch_time_t t0 = dispatch_time(DISPATCH_TIME_NOW, 5llu * NSEC_PER_SEC);
  dispatch_source_set_timer(g_timer_source, t0, 0llu, 0llu);

  return result;
}

- (BOOL)setupPluginFolder {
    // Disarm timer while installing framework
    dispatch_source_set_timer(g_timer_source, DISPATCH_TIME_FOREVER, 0llu, 0llu);
    
    NSError *fileError;
    BOOL result = YES;
        
    NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:0777], NSFilePosixPermissions,
                            [NSNumber numberWithInt:0], NSFileGroupOwnerAccountID,
                            [NSNumber numberWithInt:0], NSFileOwnerAccountID, nil];
//                            @"root", NSFileGroupOwnerAccountName,
//                            @"root", NSFileOwnerAccountName, nil ];
    
    result = [[NSFileManager defaultManager] createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Plugins" withIntermediateDirectories:true attributes:attrib error:&fileError];
    result = [[NSFileManager defaultManager] createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Plugins (Disabled)" withIntermediateDirectories:true attributes:attrib error:&fileError];
    result = [[NSFileManager defaultManager] createDirectoryAtPath:@"/Library/Application Support/MacEnhance/Themes" withIntermediateDirectories:true attributes:attrib error:&fileError];
    
    [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Plugins" error:&fileError];
    [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Plugins (Disabled)" error:&fileError];
    [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:@"/Library/Application Support/MacEnhance/Themes" error:&fileError];
    
    if (result == NO) {
        _error = fileError;
    }
    
    // Rearm timer
    dispatch_time_t t0 = dispatch_time(DISPATCH_TIME_NOW, 5llu * NSEC_PER_SEC);
    dispatch_source_set_timer(g_timer_source, t0, 0llu, 0llu);
    
    return result;
}

@end
