//
//  Loader.c
//  Loader
//
//  Created by Jeremy on 11/5/20.
//

#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <string.h>
#include "CFUtils.h"
#include <os/log.h>
#include <sys/syslimits.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/stat.h>


#define likely(x) (!!(x))
#define unlikely(x) (!!(x))

const char *pluginsPath = "/Library/Application Support/MacEnhance/Plugins/";
bool isGraylisted = false;

#define bswap16(value) \
((((value) & 0xff) << 8) | ((value) >> 8))

#define bswap32(value) \
(((uint32_t)bswap16((uint16_t)((value) & 0xffff)) << 16) | \
(uint32_t)bswap16((uint16_t)((value) >> 16)))

#define bswap64(value) \
(((uint64_t)bswap32((uint32_t)((value) & 0xffffffff)) \
<< 32) | \
(uint64_t)bswap32((uint32_t)((value) >> 32)))

#define bswapN(x,n) bswap64((x) << ((8-(n)) << 3))

#define BSWAP(x, n) \
({ \
    ((n) >= 8 ? bswap64( *(uint64_t *)(x) ) : \
    ((n) == 4 ? bswap32( *(uint32_t *)(x) ) : \
    ((n) == 2 ? bswap16( *(uint16_t *)(x) ) : \
        ((n) == 1 ? *(uint8_t *)(x) : \
    bswapN( *(uint64_t *)(x), n))))); \
})

static int _strncmp_fast(const char *ptr0, const char *ptr1, size_t len) {
    size_t fast = len/sizeof(size_t) + 1;
    size_t offset = (fast-1)*sizeof(size_t);
    int current_block = 0;
    
    if( len <= sizeof(size_t)){ fast = 0; }
    
    
    size_t *lptr0 = (size_t*)ptr0;
    size_t *lptr1 = (size_t*)ptr1;
    
    while( current_block < fast ){
        if( (lptr0[current_block] ^ lptr1[current_block] )){
            int pos;
            for(pos = current_block*sizeof(size_t); pos < len ; ++pos ){
                if( (ptr0[pos] ^ ptr1[pos]) || (ptr0[pos] == 0) || (ptr1[pos] == 0) ){
                    return  (int)((unsigned char)ptr0[pos] - (unsigned char)ptr1[pos]);
                }
            }
        }
        
        ++current_block;
    }
    
    while( len > offset ){
        if( (ptr0[offset] ^ ptr1[offset] )){
            return (int)((unsigned char)ptr0[offset] - (unsigned char)ptr1[offset]);
        }
        ++offset;
    }
    
    
    return 0;
}

typedef struct {
    uint64_t base;
    struct _trailer {
        uint32_t unused;
        uint8_t offset_table_offset_size;
        uint8_t object_ref_size;
        uint64_t num_objects;
        uint64_t top_object_offset;
        uint64_t offset_table_start;
    } trailer;
} bplist00;

int bplist_new(uint8_t *bplist_src, size_t size, bplist00 *bplist) {
    bplist->base = (uint64_t)bplist_src;
    size_t offset = (uint64_t)bplist_src + (size - 32);
    bplist->trailer.offset_table_offset_size = *(uint8_t *)(offset + 6);
    bplist->trailer.object_ref_size = *(uint8_t *)(offset + 7);
    bplist->trailer.num_objects = bswap64(*(uint64_t *)(offset + 8));
    bplist->trailer.top_object_offset = bswap64(*(uint64_t *)(offset + 16));
    bplist->trailer.offset_table_start = bswap64(*(uint64_t *)(offset + 24));
    return 0;
}

uint64_t bplist_get_node_size(char *node) {
    uint8_t size_mask = 0x0F;
    if ((*node & size_mask) != size_mask) {
        return (*node & size_mask);
    }
    
    uint64_t width = (1 << (node[1] & size_mask));
    return BSWAP(&node[2], width);
}

uint64_t bplist_read_node_size(const char **node) {
    uint8_t size_mask = 0x0F;
    uint64_t size = (**node & size_mask);
    (*node)++;
    if (size != size_mask) {
        return size;
    }
    
    uint64_t width = (1 << (**node & size_mask));
    (*node)++;
    size = BSWAP(*node, width);
    (*node)++;
    return size;
}

uint64_t bplist_str_for_key(bplist00 *bplist, char *key, char *val) {
    uint64_t base = bplist->base;
    uint8_t offset_size = bplist->trailer.offset_table_offset_size;
    uint8_t ref_size = bplist->trailer.object_ref_size;
    uint64_t first_offset_entry = BSWAP((void*)(base + (bplist->trailer.offset_table_start)), offset_size);
    char *base_dict = (char*)(base + first_offset_entry);
    uint64_t base_dict_num_keys = bplist_get_node_size(base_dict);
    char *base_dict_keys_start = base_dict_num_keys > 0xE ? &base_dict[3] : &base_dict[1];
    char *base_dict_vals_start = (char*)((uint64_t)base_dict_keys_start + (base_dict_num_keys * bplist->trailer.object_ref_size));
    
    for (int i = 0; i < base_dict_num_keys; i++) {
        uint64_t index = BSWAP((void*)((uint64_t)base_dict_keys_start + (i * ref_size)), ref_size);
        char *offset_entry = (char *)(base + (bplist->trailer.offset_table_start + (index * offset_size)));
        uint64_t offset = BSWAP(offset_entry, offset_size);
        
        const char *node = (const char*)(base + offset);
        if ((*node & 0xF0) != 0x50) continue;
        uint64_t size = bplist_read_node_size(&node);
        if (size != strlen(key)) continue;
        if (_strncmp_fast(node, key, size) != 0) continue;

        
        uint64_t val_index = BSWAP((void*)((uint64_t)base_dict_vals_start + (i * ref_size)), ref_size);
        char *value_offset_entry = (char *)(base + (bplist->trailer.offset_table_start + (val_index * offset_size)));
        uint64_t value_offset = BSWAP(value_offset_entry, offset_size);
        const char *value_node = (const char*)(base + value_offset);
        if ((*value_node & 0xF0) != 0x50) continue;
        size = bplist_read_node_size(&value_node);
        
        memcpy(val, value_node, size);
        return size;
    }
    return 0;
}

char *getElemContents(const char *XMLBlob, char *Tag, uint64_t *len) {
    
    char *tagBegin = alloca(strlen(Tag) + 5);
    tagBegin[0] = '<';
    strcpy(tagBegin + 1, Tag); // could be more efficient
    if (strcmp(Tag, "plist"))
        strcat(tagBegin, ">");
    
    char *tagActualBegin = strstr(XMLBlob, tagBegin);
    if (!tagActualBegin) {
        
        return NULL;
    }
    char *tagEnd = strchr(tagActualBegin, '>');
    if (!tagEnd)
        return NULL;
    char *elemContents = tagEnd + 1;
    while (elemContents[0] == '\n') {
        elemContents++;
    }
    char *elemEnd = alloca(strlen(Tag) + 5);
    elemEnd[0] = '<';
    elemEnd[1] = '/';
    strcpy(elemEnd + 2, Tag);
    strcat(elemEnd, ">"); // could be more efficient
    
    char *sameElem = strstr(elemContents, tagBegin);
    char *elemEndx = strstr(elemContents, elemEnd);
    if (!elemEndx)
        return NULL;
    
    int nesting = 0;
    
    if (sameElem && (elemEndx > sameElem))
        nesting++;
    
    while (nesting) {
        
        // So there is a nested <elem> before </elem>
        if (sameElem)
            sameElem = strstr(sameElem + 1, tagBegin);
        if (!sameElem) {
            nesting--;
            if (elemEndx)
                elemEndx = strstr(elemEndx + 2, elemEnd);
        } else if (sameElem > elemEndx) {
            elemEndx = strstr(elemEndx + 1, elemEnd);
        } else {
            nesting++;
            continue;
        }
    }
    
    // Out of nesting
    
    if (elemEndx) {
        uint64_t start = (uint64_t)elemContents;
        uint64_t end = (uint64_t)elemEndx;
        *len = (end - start) - 1;
    }
    return (elemContents);
};

char *getNextTag(const char *xml_blob) {
    
    static char returned[16];
    returned[0] = '\0';
    
    char *tagBegin = strchr(xml_blob, '<');
    
    if (tagBegin && (tagBegin[1] == '!') && (tagBegin[2] == '-') &&
        (tagBegin[3] == '-')) {
        char *comment = strstr(xml_blob, "-->");
        if (comment)
            tagBegin = strchr(comment + 3, '<');
        else {
            fprintf(stderr, "Unterminated comment!\n");
            return NULL;
        }
    }
    
    while (tagBegin && tagBegin[1] == '/') {
        xml_blob = tagBegin + 1;
        tagBegin = strchr(xml_blob, '<');
    }
    if (!tagBegin)
        return NULL;
    int i = 0;
    for (i = 0; i < 14; i++) {
        if ((tagBegin[i + 1] == ' ') || (tagBegin[i + 1] == '>')) {
            returned[i] = '\0';
            return (returned);
        }
        
        returned[i] = tagBegin[i + 1];
        
    }
    
    return NULL;
}

char *xml_plist_value_for_key(const char *blob, char *key, uint64_t *length) {
    size_t size = strlen(blob);
    uint64_t end = (uint64_t)blob + size;
    while ((uint64_t)blob < end) {
        uint64_t len = 0;
        blob = getElemContents(blob, "key", &len);
        if (!blob)
            return NULL;
        if (_strncmp_fast(blob, key, strlen(key)) == 0) {
            blob = (char *)((uint64_t)blob + len);
            char *nextElem = getNextTag(blob);
            char *elemContents = getElemContents(blob, nextElem, &len);
            *length = (len + 1);
            return elemContents;
        }
    }
    return NULL;
}

// In the interest of speed, process_extensions does not do any kind of sorting
__attribute__((__always_inline__))
static void process_extensions(char *identifier) {
    if (unlikely(access(pluginsPath, R_OK) != 0)) {
        return;
    }
    
    DIR *dr = opendir(pluginsPath);
    if (unlikely(dr == NULL)) {
        printf("Could not open current directory" );
        return;
    }
    
    char *pluginPlist = NULL;
    kern_return_t kr = vm_allocate(mach_task_self(), (vm_address_t*) &pluginPlist, 4000, VM_FLAGS_ANYWHERE);
    if (unlikely(kr != KERN_SUCCESS)) {
        closedir(dr);
        return;
    }
    
    struct dirent *de;
    while ((de = readdir(dr)) != NULL) {
        if (strstr(de->d_name, ".bundle") && de->d_type == DT_DIR) {
            char info_plist[PATH_MAX] = {0};
            strcpy(info_plist, pluginsPath);
            strcat(info_plist, de->d_name);
            strcat(info_plist, "/Contents/Info.plist");
            
            if (unlikely(access(info_plist, R_OK) != 0)) {
                continue;
            }
            
            int inputFD = open(info_plist, O_RDONLY);
            struct stat stBuf = {0};
            fstat(inputFD, &stBuf);
          
            off_t inputSize = stBuf.st_size;
            read(inputFD, pluginPlist, inputSize);

            char *plist = strstr(pluginPlist, "<plist ");
            uint64_t len = 0;
            char *libExecutable = xml_plist_value_for_key(plist, "CFBundleExecutable", &len);
            if (unlikely(!libExecutable)) {
                close(inputFD);
                continue;
            }
            
            char fullLibPath[PATH_MAX] = {0};
            strcpy(fullLibPath, pluginsPath);
            strcat(fullLibPath, de->d_name);
            strcat(fullLibPath, "/Contents/MacOS/");
            strncat(fullLibPath, libExecutable, len);
            
            len = 0;
            char *dict = xml_plist_value_for_key(plist, "SIMBLTargetApplications", &len);
            uint64_t end = (uint64_t)dict + len;
            while ((uint64_t)dict < end) {
                uint64_t len = 0;
                dict = xml_plist_value_for_key(dict, "BundleIdentifier", &len);
                if (!dict) break;
                
                if (_strncmp_fast(dict, identifier, strlen(identifier)) == 0) {
                    dlopen(fullLibPath, RTLD_LAZY);
                    continue;
                }
                
                if(unlikely(isGraylisted)) {
                    continue;
                }
                
                if (dict[0] == '*') {
                    dlopen(fullLibPath, RTLD_LAZY);
                }
            }
            close(inputFD);
        }
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)pluginPlist, 4000);
    closedir(dr);
}


__attribute__((constructor))
static void loader_ctor(int argc, char **argv, char **envp) {
    
    /*
     Housekeeping
     */
    if (argc < 1 || argv == NULL) return;
    
    char *executable = strrchr(argv[0], '/');
    executable = (executable == NULL) ? argv[0] : executable + 1;
    if(unlikely(!executable)) return;
    
    uint32_t mrt = 0x0054524D;
    if (unlikely(*(uint32_t*)executable == mrt)) return;
//    if(unlikely(strcmp(executable, "MRT") == 0)) return;
    
    /* Graylist:
     Plugins won't load into processes from these directories unless
     specifically targeted in 'SIMBLTargetApplications'.
     Note: Finder is eventually removed from graylist
     */
    if(unlikely(_strncmp_fast(argv[0], "/usr", 4) == 0))
        isGraylisted = true;
    
    if(unlikely(_strncmp_fast(argv[0], "/System/Library", 15) == 0))
        isGraylisted = true;
    
    if(unlikely(_strncmp_fast(argv[0], "/sbin", 5) == 0))
        isGraylisted = true;
    
    /*
     * The good stuff
     */
    
    size_t plistSize = 0;
    const char *infoPlist = CreateInfoDictionaryForExecutable(argv[0], &plistSize);
    if(unlikely(!infoPlist)) {
        return;
    }
    
    char packageType[5] = {0};
    char identifier[1024] = {0};
    
    if (unlikely(_strncmp_fast(infoPlist, "bplist", 6) == 0)) {
        os_log(OS_LOG_DEFAULT, "libLoader: Plist is bplist");
        
        bplist00 bplist = {0};
        bplist_new((uint8_t *)infoPlist, plistSize, &bplist);
        
        uint64_t readSize = bplist_str_for_key(&bplist, "CFBundlePackageType", packageType);
        if (unlikely(readSize == 0)) {
            os_log(OS_LOG_DEFAULT, "libLoader: Could not find bundle package type");
            memcpy(packageType, "APPL", 4);
        }
        
        readSize = bplist_str_for_key(&bplist, "CFBundleIdentifier", identifier);
        if (unlikely(readSize == 0)) {
            os_log(OS_LOG_DEFAULT, "libLoader: Could not find CFBundleIdentifier");
            return;
        }
        
    } else {
        uint64_t len = 0;
        char *plist = strstr((char *)infoPlist, "<plist ");
        char *package = xml_plist_value_for_key(plist, "CFBundlePackageType", &len);
        if (unlikely(len == 0)) {
            package = "APPL";
        }
        memcpy(packageType, package, 4);
        
        len = 0;
        char *bundleId = xml_plist_value_for_key(plist, "CFBundleIdentifier", &len);
        if(unlikely(!bundleId)) {
            os_log(OS_LOG_DEFAULT, "libLoader: Could not find CFBundleIdentifier");
            return;
        }
        
        strncpy(identifier, bundleId, len);
    }
    
    //APPL -> LPPA -> 0x4c505041
    uint32_t APPL = 0x4c505041;
    if (unlikely(*(uint32_t *)packageType != APPL)) {
        isGraylisted = 1;
    }
    
    //os_log(OS_LOG_DEFAULT, "libLoader: %s", identifier);
    
    size_t identifierLen = strlen(identifier);
    if (unlikely(_strncmp_fast(identifier, "com.apple.dock", identifierLen) == 0)) {
        dlopen("/Library/Application Support/MacEnhance/CorePlugins/DockKit.bundle/Contents/MacOS/DockKit", RTLD_NOW);
    }
    
    if (unlikely(_strncmp_fast(identifier, "com.apple.finder", identifierLen) == 0)) {
        isGraylisted = 0;
    }
    
    process_extensions(identifier);
    free((void*)infoPlist);
    
    return;
}
