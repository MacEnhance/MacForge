//
//  UniversalInj.h
//  UniversalInj
//
//  Created by Jeremy on 12/1/20.
//

#ifndef UniversalInj_h
#define UniversalInj_h

#include <stdio.h>
#include <sys/types.h>    //NOTE: Added

void inject(pid_t pid, const char *lib);
void inject_sync(pid_t pid, const char *lib);

#endif /* UniversalInj_h */
