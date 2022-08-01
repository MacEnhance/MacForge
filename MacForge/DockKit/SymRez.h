//
//  SymRez.h
//  MyBad
//
//  Created by j on 4/24/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#ifndef SymRez_h
#define SymRez_h

#include <stdio.h>

struct symrez_struct;
typedef struct symrez_struct* symrez_t;

/*! @function symrez_new
    @abstract Create new symrez object
    @param image_name Name of the  library to symbolicate. Pass NULL for current executable  */
symrez_t symrez_new(const char *image_name);
symrez_t symrez_new_with_header(void *header);

/*! @function sr_resolve_symbol
    @abstract Create new symrez object
    @param symrez symrez object created by symrez_new
    @param symbol Mangled symbol name
    @return Pointer to symbol location */
void * sr_resolve_symbol(symrez_t symrez, const char *symbol);

#endif /* SymRez_h */
