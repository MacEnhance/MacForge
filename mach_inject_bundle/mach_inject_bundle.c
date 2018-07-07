// mach_inject_bundle.c semver:1.3.0
//   Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/mach_inject

#include "mach_inject_bundle.h"
#include "mach_inject.h"
#include "mach_inject_bundle_stub.h"
#include <CoreServices/CoreServices.h>

	mach_error_t
mach_inject_bundle_pid(
		const char	*bundlePackageFileSystemRepresentation,
		pid_t		pid )
{
	assert( bundlePackageFileSystemRepresentation );
	assert( pid > 0 );
	
	mach_error_t	err = err_none;
	
	//	Get the framework's bundle.
	CFBundleRef frameworkBundle = NULL;
	if( !err ) {
		frameworkBundle = CFBundleGetBundleWithIdentifier(
			CFSTR("com.rentzsch.mach_inject_bundle"));
		if( frameworkBundle == NULL )
			err = err_mach_inject_bundle_couldnt_load_framework_bundle;
	}
	
	//	Find the injection bundle by name.
	CFURLRef injectionURL = NULL;
	if( !err ) {
		/*injectionURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, CFSTR("mach_inject_bundle_stub.bundle"),
			kCFURLPOSIXPathStyle, true );*/
		injectionURL = CFBundleCopyResourceURL( frameworkBundle,
			CFSTR("mach_inject_bundle_stub.bundle"), NULL, NULL );
		
		/*char url[1024];
		CFURLGetFileSystemRepresentation(injectionURL, true, url, 1024);
		printf("got a URL %s\n", url);*/
		if( !injectionURL )
			err = err_mach_inject_bundle_couldnt_find_injection_bundle;
	}
	
	//	Create injection bundle instance.
	CFBundleRef injectionBundle = NULL;
	if( !err ) {
		injectionBundle = CFBundleCreate( kCFAllocatorDefault, injectionURL );
		if( !injectionBundle )
			err = err_mach_inject_bundle_couldnt_load_injection_bundle;
	}
	
	//	Load the thread code injection.
	void *injectionCode = NULL;
	if( !err ) {
		injectionCode = CFBundleGetFunctionPointerForName( injectionBundle,
			CFSTR( INJECT_ENTRY_SYMBOL ));
		if( injectionCode == NULL )
			err = err_mach_inject_bundle_couldnt_find_inject_entry_symbol;
	}
	
	//	Allocate and populate the parameter block.
	mach_inject_bundle_stub_param *param = NULL;
	size_t paramSize;
	if( !err ) {
		size_t bundlePathSize = strlen( bundlePackageFileSystemRepresentation )
			+ 1;
		paramSize = sizeof( ptrdiff_t ) + bundlePathSize;
		param = malloc( paramSize );
		bcopy( bundlePackageFileSystemRepresentation,
			   param->bundlePackageFileSystemRepresentation,
			   bundlePathSize );
	}
	
	//	Inject the code.
	if( !err ) {
		err = mach_inject( injectionCode, param, paramSize, pid, 0 );
	}
	
	//	Clean up.
	if( param )
		free( param );
	/*if( injectionBundle )
		CFRelease( injectionBundle );*/
	if( injectionURL )
		CFRelease( injectionURL );
	
	return err;
}