/**
 * Copyright 2003-2009, Mike Solomon <mas63@cornell.edu>
 * SIMBL is released under the GNU General Public License v2.
 * http://www.opensource.org/licenses/gpl-2.0.php
 */

#import "DTMacros.h"
#import "SIMBL.h"
#import "SIMBLPlugin.h"
#import "NSAlert_SIMBL.h"
#import "DKInjectorProxy.h"

#import <objc/objc-class.h>

/*
	<key>SIMBLTargetApplications</key>
	<array>
		<dict>
			<key>BundleIdentifier</key>
			<string>com.apple.Safari</string>
			<key>MinBundleVersion</key>
			<integer>125</integer>
			<key>MaxBundleVersion</key>
			<integer>125</integer>
		</dict>
	</array>
*/


OSErr pascal InjectEventHandler(const AppleEvent *ev, AppleEvent *reply, SInt32 refcon)
{
    OSErr resultCode = noErr;
    SIMBLLogInfo(@"load SIMBL plugins");
    [SIMBL installPlugins];
    return resultCode;
}

@implementation SIMBL

static NSMutableDictionary* loadedBundleIdentifiers = nil;

+ (void) initialize
{
	NSUserDefaults* defaults = [[NSUserDefaults alloc] init];
	[defaults addSuiteNamed:@"net.culater.SIMBL"];
	[defaults registerDefaults:@{SIMBLPrefKeyLogLevel: @SIMBLLogLevelDefault}];
}

+ (void) logMessage:(NSString*)message atLevel:(int)level
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults addSuiteNamed:@"net.culater.SIMBL"];
	if ([defaults integerForKey:SIMBLPrefKeyLogLevel] <= level) {
		NSLog(@"%@", message);
	}
}

+ (NSArray*) pluginPathList
{
	NSMutableArray* pluginPathList = [NSMutableArray array];
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,  NSUserDomainMask | NSLocalDomainMask | NSNetworkDomainMask, YES);
	for (NSString* libraryPath in paths) {
		NSString* simblPath = [libraryPath stringByAppendingPathComponent:SIMBLPluginPath];
        NSArray* simblBundles = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:simblPath error:nil] pathsMatchingExtensions:@[@"bundle"]];
		for (NSString* bundleName in simblBundles) {
			[pluginPathList addObject:[simblPath stringByAppendingPathComponent:bundleName]];
		}
	}
	return pluginPathList;
}

+ (NSArray*)pluginsToLoadList :(NSBundle*)appBundle
{
    NSMutableArray *plugins = [[NSMutableArray alloc] init];
    for (NSString *path in [self pluginPathList]) {
        if ([self shouldApplication:appBundle loadBundleAtPath:path])
            [plugins addObject:path];
    }
    return plugins.copy;
}


+ (void) installPlugins
{
	if (loadedBundleIdentifiers == nil)
		loadedBundleIdentifiers = [[NSMutableDictionary alloc] init];
	
	SIMBLLogDebug(@"SIMBL loaded by path %@ <%@>", [[NSBundle mainBundle] bundlePath], [[NSBundle mainBundle] bundleIdentifier]);
	
	for (NSString* path in [SIMBL pluginPathList]) {
		BOOL bundleLoaded = [SIMBL loadBundleAtPath:path];
		if (bundleLoaded)
			SIMBLLogDebug(@"loaded %@", path);
	}
}


+ (BOOL) shouldInstallPluginsIntoApplication:(NSBundle*)_appBundle
{
	for (NSString* path in [SIMBL pluginPathList]) {
		BOOL bundleLoaded = [SIMBL shouldApplication:_appBundle loadBundleAtPath:path];
		if (bundleLoaded)
			return YES;
	}
	return NO;
}


/**
 * get this list of allowed application identifiers from the plugin's Info.plist
 * the special value * will cause any Cocoa app to load a bundle
 * @return YES if this should be loaded
 */
+ (BOOL) shouldLoadBundleAtPath:(NSString*)_bundlePath
{
	NSBundle* appBundle = [NSBundle mainBundle];
	return [SIMBL shouldApplication:appBundle loadBundleAtPath:_bundlePath];
}


/**
 * get this list of allowed application identifiers from the plugin's Info.plist
 * the special value * will cause any Cocoa app to load a bundle
 * @return YES if this should be loaded
 */
+ (BOOL) shouldApplication:(NSBundle*)_appBundle loadBundleAtPath:(NSString*)_bundlePath
{
	SIMBLLogDebug(@"checking bundle %@", _bundlePath);
	_bundlePath = _bundlePath.stringByStandardizingPath;
	SIMBLPlugin* pluginBundle = [SIMBLPlugin bundleWithPath:_bundlePath];
	if (pluginBundle == nil) {
		SIMBLLogNotice(@"Unable to load bundle at path '%@'", _bundlePath);
		return NO;
	}
	
	NSString* pluginIdentifier = [pluginBundle bundleIdentifier];
	if (pluginIdentifier == nil) {
		SIMBLLogNotice(@"No identifier for bundle at path '%@'", _bundlePath);
		return NO;
	}
	
	// this is the new way of specifying when to load a bundle
	NSArray* targetApplications = [pluginBundle objectForInfoDictionaryKey:SIMBLTargetApplications];
	if (targetApplications)
		return [self shouldApplication:_appBundle loadBundle:pluginBundle withTargetApplications:targetApplications];
	
	// fall back to the old method for older plugins - we should probably throw a depreaction warning
	NSArray* applicationIdentifiers = [pluginBundle objectForInfoDictionaryKey:SIMBLApplicationIdentifier];
	if (applicationIdentifiers)
		return [self shouldApplication:_appBundle loadBundle:pluginBundle withApplicationIdentifiers:applicationIdentifiers];
	
	return NO;
}


/**
 * get this list of allowed application identifiers from the plugin's Info.plist
 * the special value * will cause any Cocoa app to load a bundle
 * if there is a match, this calls the main bundle's load method
 * @return YES if this bundle was loaded
 */
+ (BOOL) loadBundleAtPath:(NSString*)_bundlePath
{
	if ([SIMBL shouldLoadBundleAtPath:_bundlePath] == NO) {
		return NO;
	}
	
	SIMBLPlugin* pluginBundle = [SIMBLPlugin bundleWithPath:_bundlePath];

	// check to see if we already loaded code for this identifier (keeps us from double loading)
	// this is common if you have User vs. System-wide installs - probably mostly for developers
	// "physician, heal thyself!"
	NSString* pluginIdentifier = [pluginBundle bundleIdentifier];
	if (loadedBundleIdentifiers[pluginIdentifier] != nil)
		return NO;
	return [SIMBL loadBundle:pluginBundle];
}


/**
 * get this list of allowed application identifiers from the plugin's Info.plist
 * the special value * will cause any Cocoa app to load a bundle
 * if there is a match, this calls the main bundle's load method
 * @return YES if this bundle was loaded
 */
+ (BOOL) shouldApplication:(NSBundle*)_appBundle loadBundle:(SIMBLPlugin*)_bundle withApplicationIdentifiers:(NSArray*)_applicationIdentifiers
{	
	NSString* appIdentifier = _appBundle.bundleIdentifier;
	for (NSString* specifiedIdentifier in _applicationIdentifiers) {
		SIMBLLogDebug(@"checking bundle %@ for identifier %@", [_bundle bundleIdentifier], specifiedIdentifier);
		if ([specifiedIdentifier isEqualToString:appIdentifier] == YES ||
			[specifiedIdentifier isEqualToString:@"*"] == YES) {
			SIMBLLogDebug(@"load bundle %@", [_bundle bundleIdentifier]);
			SIMBLLogNotice(@"The plugin %@ (%@) is using a deprecated interface to SIMBL. Please contact the appropriate developer (not the SIMBL author) and refer them to http://code.google.com/p/simbl/wiki/Tutorial", [_bundle path], [_bundle bundleIdentifier]);
			return YES;
		}
	}
	
	return NO;
}


/**
 * get this list of allowed target applications from the plugin's Info.plist
 * the special value * will cause any Cocoa app to load a bundle
 * if there is a match, this calls the main bundle's load method
 * @return YES if this bundle was loaded
 */
+ (BOOL) shouldApplication:(NSBundle*)_appBundle loadBundle:(SIMBLPlugin*)_bundle withTargetApplications:(NSArray*)_targetApplications
{
	NSString* appIdentifier = _appBundle.bundleIdentifier;
	for (NSDictionary* targetAppProperties in _targetApplications) {
		NSString* targetAppIdentifier = targetAppProperties[SIMBLBundleIdentifier];
		SIMBLLogDebug(@"checking target identifier %@", targetAppIdentifier);
		if ([targetAppIdentifier isEqualToString:appIdentifier] == NO &&
				[targetAppIdentifier isEqualToString:@"*"] == NO)
			continue;

		NSString* targetAppPath = targetAppProperties[SIMBLTargetApplicationPath];
		if (targetAppPath && [targetAppPath isEqualToString:_appBundle.bundlePath] == NO)
			continue;

		// FIXME: this has never been used - it should probably be removed.
		NSArray* requiredFrameworks = targetAppProperties[SIMBLRequiredFrameworks];
		BOOL missingFramework = NO;
		if (requiredFrameworks)
		{
			SIMBLLogDebug(@"requiredFrameworks: %@", requiredFrameworks);
			NSEnumerator* requiredFrameworkEnum = [requiredFrameworks objectEnumerator];
			NSDictionary* requiredFramework;
			while ((requiredFramework = [requiredFrameworkEnum nextObject]) && missingFramework == NO)
			{
				NSBundle* framework = [NSBundle bundleWithIdentifier:requiredFramework[@"BundleIdentifier"]];
				NSString* frameworkPath = framework.bundlePath;
				NSString* requiredPath = requiredFramework[@"BundlePath"];
				if ([frameworkPath isEqualToString:requiredPath] == NO) {				
					missingFramework = YES;
				}
			}
		}
		
		if (missingFramework)
			continue;
		
		int appVersion = [_appBundle _dt_bundleVersion].intValue;
		
		int minVersion = 0;
		NSNumber* number;
		if ((number = targetAppProperties[SIMBLMinBundleVersion]))
			minVersion = number.intValue;
			
		int maxVersion = 0;
		if ((number = targetAppProperties[SIMBLMaxBundleVersion]))
			maxVersion = number.intValue;
		
		if ((maxVersion && appVersion > maxVersion) || (minVersion && appVersion < minVersion))
		{
			[NSAlert errorAlert:NSLocalizedStringFromTableInBundle(@"Error", SIMBLStringTable, DTOwnerBundle, @"Error alert primary message") withDetails:NSLocalizedStringFromTableInBundle(@"%@ %@ (v%@) has not been tested with the plugin %@ %@ (v%@). As a precaution, it has not been loaded. Please contact the plugin developer for further information.", SIMBLStringTable, DTOwnerBundle, @"Error alert details, substitute application and plugin version strings"), [_appBundle _dt_name], [_appBundle _dt_version], [_appBundle _dt_bundleVersion], [_bundle _dt_name], [_bundle _dt_version], [_bundle _dt_bundleVersion]];
			continue;
		}
		
		return YES;
	}
	
	return NO;
}


+ (BOOL) loadBundle:(SIMBLPlugin*)_plugin
{
	@try
	{
		// getting the principalClass should force the bundle to load
		NSBundle* bundle = [NSBundle bundleWithPath:_plugin.path];
		Class principalClass = bundle.principalClass;
		
		// if the principal class has an + (void) install message, call it
		if (principalClass && class_getClassMethod(principalClass, @selector(install)))
			[principalClass install];
		
		// set that we've loaded this bundle to prevent collisions
		loadedBundleIdentifiers[bundle.bundleIdentifier] = @"loaded";
		
		return YES;
	}
	@catch (NSException* exception)
	{
		[NSAlert errorAlert:NSLocalizedStringFromTableInBundle(@"Error", SIMBLStringTable, DTOwnerBundle, @"Error alert primary message") withDetails:NSLocalizedStringFromTableInBundle(@"Failed to load the %@ plugin.\n%@", SIMBLStringTable, DTOwnerBundle, @"Error alert details, sub plugin name and error reason"), [_plugin _dt_name], exception.reason];
	}
	
	return NO;
}

@end
