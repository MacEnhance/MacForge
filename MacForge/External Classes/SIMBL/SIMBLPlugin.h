/**
 * Copyright 2003-2009, Mike Solomon <mas63@cornell.edu>
 * SIMBL is released under the GNU General Public License v2.
 * http://www.opensource.org/licenses/gpl-2.0.php
 */

#import <Foundation/Foundation.h>

@interface SIMBLPlugin : NSObject
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSDictionary *info;

+ (SIMBLPlugin*) bundleWithPath:(NSString*)path;
- (SIMBLPlugin*) initWithPath:(NSString*)path;

@property (nonatomic, readonly, copy) NSString *bundleIdentifier;
- (id) objectForInfoDictionaryKey:(NSString*)key;

@property (nonatomic, readonly, copy) NSString *_dt_info;
@property (nonatomic, readonly, copy) NSString *_dt_version;
@property (nonatomic, readonly, copy) NSString *_dt_bundleVersion;
@property (nonatomic, readonly, copy) NSString *_dt_name;

@end


@interface NSBundle (SIMBLCocoaExtensions)

@property (nonatomic, readonly, copy) NSString *_dt_info;
@property (nonatomic, readonly, copy) NSString *_dt_version;
@property (nonatomic, readonly, copy) NSString *_dt_bundleVersion;
@property (nonatomic, readonly, copy) NSString *_dt_name;

@end
