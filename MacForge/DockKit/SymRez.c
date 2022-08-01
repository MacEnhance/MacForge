//
//  SymRez.c
//  SymRez
//
//  Created by Jeremy Legendre on 4/14/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#include "SymRez.h"
#include <stdlib.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <mach-o/getsect.h>
#include <mach-o/nlist.h>

typedef const struct mach_header_64* mach_header_t;

struct symrez_struct {
    mach_header_t header;
    intptr_t slide;
};

typedef struct symrez_struct* symrez_t;

static intptr_t _compute_slide(mach_header_t mh) {
    const uint32_t cmd_count = mh->ncmds;
    struct load_command* const cmds = (struct load_command*)((char*)mh + sizeof(const struct mach_header_64));
    const struct load_command* cmd = cmds;
    for (uint32_t i = 0; i < cmd_count; ++i) {
        if ( cmd->cmd == LC_SEGMENT_64 ) {
            struct segment_command_64* seg = (struct segment_command_64*)cmd;
            if ( strcmp(seg->segname, "__TEXT") == 0 )
                return (char*)mh - (char*)(seg->vmaddr);
        }
        cmd = (const struct load_command*)(((char*)cmd)+cmd->cmdsize);
    }
    return 0;
}

struct segment_command_64 * find_segment_64(mach_header_t mh, const char *segname) {
    struct load_command *lc;
    struct segment_command_64 *seg, *foundseg = NULL;
    
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header_64));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == LC_SEGMENT_64) {
            seg = (struct segment_command_64 *)lc;
            if (strcmp(seg->segname, segname) == 0) {
                foundseg = seg;
                break;
            }
        }
        
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    
    return foundseg;
}

struct load_command * find_load_command(mach_header_t mh, uint32_t cmd) {
    struct load_command *lc, *foundlc = NULL;
    
    lc = (struct load_command *)((uint64_t)mh + sizeof(struct mach_header_64));
    while ((uint64_t)lc < (uint64_t)mh + (uint64_t)mh->sizeofcmds) {
        if (lc->cmd == cmd) {
            foundlc = (struct load_command *)lc;
            break;
        }
        
        lc = (struct load_command *)((uint64_t)lc + (uint64_t)lc->cmdsize);
    }
    
    return foundlc;
}

void * find_symbol(mach_header_t mh, intptr_t slide, const char *name) {
    struct symtab_command *symtab = NULL;
    struct segment_command_64 *linkedit = NULL;
    struct nlist_64 *nl = NULL;
    void *strtab = NULL;
    void *addr = NULL;
    uint64_t i;
    
    if (mh->magic != MH_MAGIC_64) {
        return NULL;
    }
    
    linkedit = find_segment_64(mh, SEG_LINKEDIT);
    if (!linkedit) {
        return NULL;
    }
    
    symtab = (struct symtab_command *)find_load_command(mh, LC_SYMTAB);
    if (!symtab) {
        return NULL;
    }
    
    int64_t strtab_addr = (int64_t)(linkedit->vmaddr - linkedit->fileoff) + symtab->stroff + slide;
    int64_t symtab_addr = (int64_t)(linkedit->vmaddr - linkedit->fileoff) + symtab->symoff + slide;
    
    strtab = (void *)strtab_addr;
    for (i = 0, nl = (struct nlist_64 *)symtab_addr;
         i < symtab->nsyms;
         i++, nl = (struct nlist_64 *)((int64_t)nl + sizeof(struct nlist_64)))
    {
        char *str = (char *)strtab + nl->n_un.n_strx;
        if (strcmp(str, name) == 0) {
            addr = (void *)(nl->n_value + slide);
        }
    }
    
    return addr;
}

static int find_image_and_slide(symrez_t symrez, const char *image_name) {
    int found = 0;
    uint32_t imagecount = _dyld_image_count();
    for(int i = 0; i < imagecount; i++) {
        const char *p = _dyld_get_image_name(i);
        char *img = strrchr(p, '/');
        img = (char *)&img[1];
        if(strcmp(img, image_name) == 0) {
            symrez->header = (const struct mach_header_64 *)_dyld_get_image_header(i);
            symrez->slide = _dyld_get_image_vmaddr_slide(i);
            found = 1;
            break;
        }
    }
    
    return found;
}

void set_self_image(symrez_t symrez) {
    symrez->header = (mach_header_t)_dyld_get_image_header(0);
    symrez->slide = _dyld_get_image_vmaddr_slide(0);
}

void * sr_resolve_symbol(symrez_t symrez, const char *symbol) {
    return find_symbol(symrez->header, symrez->slide, symbol);
}

symrez_t symrez_new(const char *image_name) {
    symrez_t symrez;
    
    if ((symrez = malloc(sizeof(*symrez))) == NULL) {
        return NULL;
    }
    
    if(image_name == NULL) {
        set_self_image(symrez);
        return symrez;
    }
    
    if(find_image_and_slide(symrez, image_name) != 1) {
        return NULL;
    }
    
    return symrez;
}

symrez_t symrez_new_with_header(void *header) {
    symrez_t symrez;
    
    if(header == NULL)
        return NULL;
    
    if ((symrez = malloc(sizeof(*symrez))) == NULL) {
        return NULL;
    }
    
    symrez->header = (mach_header_t)header;
    symrez->slide = _compute_slide((mach_header_t)header);
    
    return symrez;
}
