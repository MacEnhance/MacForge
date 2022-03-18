//
//  UniversalInj.h
//  UniversalInj
//
//  Created by Jeremy on 12/1/20.
//

#ifndef UniversalInj_h
#define UniversalInj_h

#include <stdio.h>
#include <sys/types.h>

void inject(pid_t pid);
void inject_sync(pid_t pid);

#endif /* UniversalInj_h */
