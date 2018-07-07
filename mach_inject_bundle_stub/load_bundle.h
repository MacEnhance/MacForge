// load_bundle.h semver:1.3.0
//   Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/mach_inject

#ifndef		_loader_
#define		_loader_

#include <mach/error.h>

#define	err_load_bundle_undefined_symbol					(err_local|1)
#define	err_load_bundle_link_failed							(err_local|2)
#define	err_load_bundle_url_from_path						(err_local|3)
#define	err_load_bundle_create_bundle						(err_local|4)
#define	err_load_bundle_package_executable_url				(err_local|5)
#define	err_load_bundle_path_from_url						(err_local|6)
#define err_load_bundle_NSObjectFileImageFailure			\
	(err_local|7+NSObjectFileImageFailure)
#define err_load_bundle_NSObjectFileImageInappropriateFile	\
	(err_local|7+NSObjectFileImageInappropriateFile)
#define err_load_bundle_NSObjectFileImageArch				\
	(err_local|7+NSObjectFileImageArch)
#define err_load_bundle_NSObjectFileImageFormat				\
	(err_local|7+NSObjectFileImageFormat)
#define err_load_bundle_NSObjectFileImageAccess				\
	(err_local|7+NSObjectFileImageAccess)
	
__BEGIN_DECLS

//	High-level: For loading 'MyBundle.bundle'. Calls load_bundle_executable().
	mach_error_t
load_bundle_package(
		const char *bundlePackageFileSystemRepresentation );

//	Low-level: For loading 'MyBundle.bundle/Contents/MacOS/MyBundle'.
	mach_error_t
load_bundle_executable(
	const char *bundleExecutableFileSystemRepresentation );

__END_DECLS
#endif	//	_loader_