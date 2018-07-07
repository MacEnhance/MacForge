// mach_inject_bundle_stub.h semver:1.3.0
//   Copyright (c) 2003-2016 Jonathan 'Wolf' Rentzsch: http://rentzsch.com
//   Some rights reserved: http://opensource.org/licenses/mit
//   https://github.com/rentzsch/mach_inject
//
//   Design inspired by SCPatchLoader by Jon Gotow of St. Clair Software:
//   http://www.stclairsoft.com

#ifndef		_mach_inject_bundle_stub_
#define		_mach_inject_bundle_stub_

#include <stddef.h> // for ptrdiff_t

typedef	struct	{
	ptrdiff_t	codeOffset;
	char		bundlePackageFileSystemRepresentation[1];
}	mach_inject_bundle_stub_param;

#endif	//	_mach_inject_bundle_stub_