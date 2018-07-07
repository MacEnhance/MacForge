// load_bundle.c semver:1.3.0
//   Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/mach_inject

#include "load_bundle.h"
#include <CoreServices/CoreServices.h>
#include <sys/syslimits.h> // for PATH_MAX.
#include <mach-o/dyld.h>
#include <dlfcn.h>

#include <mach/MACH_ERROR.h>
#define MACH_ERROR(msg, err) { if(err != err_none) mach_error(msg, err); }

	mach_error_t
load_bundle_package(
		const char *bundlePackageFileSystemRepresentation )
{
	fprintf(stderr, "mach_inject_bundle load_bundle_package: %s\n", bundlePackageFileSystemRepresentation);
	assert( bundlePackageFileSystemRepresentation );
	assert( strlen( bundlePackageFileSystemRepresentation ) );
	
	mach_error_t err = err_none;
	MACH_ERROR("mach error on bundle load", err);

	//	Morph the FSR into a URL.
	CFURLRef bundlePackageURL = NULL;
	if( !err ) {
		bundlePackageURL = CFURLCreateFromFileSystemRepresentation(
			kCFAllocatorDefault,
			(const UInt8*)bundlePackageFileSystemRepresentation,
			strlen(bundlePackageFileSystemRepresentation),
			true );
		if( bundlePackageURL == NULL )
			err = err_load_bundle_url_from_path;
	}
	MACH_ERROR("mach error on bundle load", err);

	//	Create bundle.
	CFBundleRef bundle = NULL;
	if( !err ) {
		bundle = CFBundleCreate( kCFAllocatorDefault, bundlePackageURL );
		if( bundle == NULL )
			err = err_load_bundle_create_bundle;
	}
	MACH_ERROR("mach error on bundle load", err);

	//	Discover the bundle's executable file.
	CFURLRef bundleExecutableURL = NULL;
	if( !err ) {
		assert( bundle );
		bundleExecutableURL = CFBundleCopyExecutableURL( bundle );
		if( bundleExecutableURL == NULL )
			err = err_load_bundle_package_executable_url;
	}
	MACH_ERROR("mach error on bundle load", err);

	//	Morph the executable's URL into an FSR.
	char bundleExecutableFileSystemRepresentation[PATH_MAX];
	if( !err ) {
		assert( bundleExecutableURL );
		if( !CFURLGetFileSystemRepresentation(
			bundleExecutableURL,
			true,
			(UInt8*)bundleExecutableFileSystemRepresentation,
			sizeof(bundleExecutableFileSystemRepresentation) ) )
		{
			err = err_load_bundle_path_from_url;
		}
	}
	MACH_ERROR("mach error on bundle load", err);

	//	Do the real work.
	if( !err ) {
		assert( strlen(bundleExecutableFileSystemRepresentation) );
		err = load_bundle_executable( bundleExecutableFileSystemRepresentation);
	}
	
	//	Clean up.
	if( bundleExecutableURL )
		CFRelease( bundleExecutableURL );
	/*if( bundle )
		CFRelease( bundle );*/
	if( bundlePackageURL )
		CFRelease( bundlePackageURL );
	
	MACH_ERROR("mach error on bundle load", err);
	return err;
}

	mach_error_t
load_bundle_executable(
		const char *bundleExecutableFileSystemRepresentation )
{
	assert( bundleExecutableFileSystemRepresentation );

	/*
	NSBundle* bundle = [NSBundle bundleWithPath:[NSString stringWithUTF8String:bundleExecutableFileSystemRepresentation]];
	
	if(![bundle load]) {
		fprintf(stderr, "mach_inject: failed to load %s\n", bundleExecutableFileSystemRepresentation);
		return err_load_bundle_NSObjectFileImageFailure;
	}
	else
		fprintf(stderr, "mach_inject: loaded succesfull: %s\n", bundleExecutableFileSystemRepresentation);
	*/
	
	//fprintf(stderr, "FS rep %s\n", bundleExecutableFileSystemRepresentation);
	void *image = dlopen(bundleExecutableFileSystemRepresentation, RTLD_NOW);
	//fprintf(stderr, "OH shit load? %p\n", image);
	if (!image) {
		dlerror();
		return err_load_bundle_NSObjectFileImageFailure;
	}

	return 0;
}