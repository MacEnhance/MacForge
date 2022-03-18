//
//  CFUtils.h
//  Loader
//
//  Created by Jeremy on 11/25/21.
//

#ifndef CFUtils_h
#define CFUtils_h

//#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
const char * CreateInfoDictionaryForExecutable(const char * execPath, size_t *size);

const char * CreateMainInfoDictionary(void);

#endif /* CFUtils_h */
