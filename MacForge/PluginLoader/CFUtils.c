//
//  CFUtils.c
//  Loader
//
//  Created by Jeremy on 11/25/21.
//

#include "CFUtils.h"
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach-o/arch.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <os/log.h>

#define PLIST_SECTION "__info_plist"

char * _infoDictFromBinary(const struct mach_header_64 *mh, intptr_t slide) {
    const struct section_64 *sp = getsectbynamefromheader_64(mh, SEG_TEXT, PLIST_SECTION);
    if (!sp) return NULL;

    char *plist = malloc(sp->size);
    memcpy(plist, (void*)(sp->addr + slide), sp->size);
    return plist;
}

static char * _infoDictFromMainBinary() {
    return _infoDictFromBinary((const struct mach_header_64 *)_dyld_get_image_header(0), _dyld_get_image_vmaddr_slide(0));
}

static int _plistPathForExec(const char *execPath, char *plistPathOut) {
    char *plistPath = plistPathOut;
    bool hasPlistFile = false;
    
    char *exec = strrchr(execPath, '/');
    if (!exec) return hasPlistFile;
    
    memcpy(plistPath, execPath, strlen(execPath) - strlen(exec));
    // plist path contains ...../Contents/MacOS (maybe)
   
    char *macFolder = strrchr(plistPath, '/'); // Go back one more '/'
    if (macFolder) {
        if (strncmp(macFolder, "/Mac", 4) == 0) {
            char *infoPlist = "Info.plist";
            unsigned infoPlistLen = (unsigned)strlen(infoPlist);
            memcpy(&plistPath[strlen(plistPath) - 5], infoPlist, infoPlistLen);
            if(access(plistPath, R_OK) == 0)
                hasPlistFile = true;
        }
    }

    return hasPlistFile;
}

static int _mapFile(char *filename, const char **buf, size_t *size) {
    int fd;
    struct stat s;

    if((fd = open(filename, O_RDONLY)) == -1) {
        return 0;
    }
    if(fstat(fd, &s)) {
        return 0;
    }
    
    if(*size == 0) *size = s.st_size;

    *buf = malloc(s.st_size);
    
    if(read(fd, (void*)*buf, *size * sizeof(char)) != *size) {
        free((void*)*buf);
        *buf = NULL;
        return 0;
    }

    close(fd);
    return 1;
}

static const char * _infoDictFromFile(char *path, size_t *size) {
    const char *buf = NULL;
    
    const char * result = NULL;
    if (_mapFile(path, &buf, size)) {
        result = (const char *)buf;
    }
    
    return result;
}

const char * CreateInfoDictionaryForExecutable(const char * execPath, size_t *size) {
    char plistPath[2048] = { 0 };
    if (!execPath) return NULL;
    
    if (_plistPathForExec(execPath, plistPath)) {
        return _infoDictFromFile(plistPath, size);
    }

    return _infoDictFromMainBinary();
}
