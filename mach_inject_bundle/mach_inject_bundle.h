// mach_inject_bundle.h semver:1.3.0
//   Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/mach_inject

/*******************************************************************************
	Higher-level interface for mach_inject. This framework, intended to be
	embedded into your application, allows you to "inject and forget" an
	arbitrary bundle into an arbitrary process. It supplies the primitive code
	block that gets squirted across the address spaces
	(mach_inject_bundle_stub), which was the trickiest thing to write.
	
	@todo	Supply a higher-level interface to specifying processes than just a
			process ID. I'm thinking offering lookup via application ID
			("com.apple.Finder").

	***************************************************************************/

#ifndef		_mach_inject_bundle_
#define		_mach_inject_bundle_

#include <sys/types.h>
#include <mach/error.h>

#define	err_mach_inject_bundle_couldnt_load_framework_bundle	(err_local|1)
#define	err_mach_inject_bundle_couldnt_find_injection_bundle	(err_local|2)
#define	err_mach_inject_bundle_couldnt_load_injection_bundle	(err_local|3)
#define	err_mach_inject_bundle_couldnt_find_inject_entry_symbol	(err_local|4)

__BEGIN_DECLS

/*******************************************************************************
	@param	bundlePackageFileSystemRepresentation	->	Required pointer
	@param	pid										->	
	@result											<-	mach_error_t

	***************************************************************************/

	mach_error_t
mach_inject_bundle_pid(
		const char	*bundlePackageFileSystemRepresentation,
		pid_t		pid );

__END_DECLS
#endif	//	_mach_inject_bundle_