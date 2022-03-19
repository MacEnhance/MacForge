//
//  Paddle+Paddle_Mutable.m
//  MacForge
//
//  Created by Jeremy on 11/19/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "Paddle+Paddle_Mutable.h"
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_images.h>
#include <mach-o/getsect.h>
#include <mach-o/nlist.h>

Paddle * __strong *gSharedInstance = NULL;

typedef const struct mach_header_64* mach_header_t;

struct symrez_struct {
    mach_header_t header;
    intptr_t slide;
};

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

@implementation Paddle (Paddle_Mutable)

+ (nullable instancetype)newSharedInstanceWithVendorID:(nonnull NSString *)vendorID
                                                apiKey:(nonnull NSString *)apiKey
                                             productID:(nonnull NSString *)productID
                                         configuration:(nonnull PADProductConfiguration *)configuration
                                              delegate:(nullable id<PaddleDelegate>)delegate {
    
    if (gSharedInstance) {
        Paddle *shared = *gSharedInstance;
        if (shared) {
            *gSharedInstance = nil;
        }
    }
    return [Paddle sharedInstanceWithVendorID:vendorID apiKey:apiKey productID:productID configuration:configuration delegate:delegate];
}

+ (void)load {
    int found = 0;
    char *paddlePath;
    uint32_t imagecount = _dyld_image_count();
    for(int i = 0; i < imagecount; i++) {
        const char *p = _dyld_get_image_name(i);
        char *img = strrchr(p, '/');
        img = (char *)&img[1];
        if(strcmp(img, "Paddle") == 0) {
            found = i;
            paddlePath = (char*)p;
            break;
        }
    }
    
    if (found) {
        mach_header_t header = (const struct mach_header_64 *)_dyld_get_image_header(found);
        intptr_t slide = _dyld_get_image_vmaddr_slide(found);
        gSharedInstance = (Paddle* __strong *)find_symbol(header, slide, "__ZL14sharedInstance");
    }
}
@end
