//
//  UniversalInj.c
//  UniversalInj
//
//  Created by Jeremy on 12/1/20.
//

#include "UniversalInj.h"
#include <unistd.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach/error.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <pthread.h>
#include <mach/mach_vm.h>
#include <dispatch/dispatch.h>

#if defined(__x86_64__)
#include <mach/thread_status.h>
#elif defined(__arm64__)
#include <mach/arm/thread_status.h>
#include <mach/arm/_structs.h>
#include <ptrauth.h>
#endif

#define ADDR_TO_PTR(a) ((void*) (unsigned long) (a))

kern_return_t (*_thread_convert_thread_state)(thread_act_t thread, int direction, thread_state_flavor_t flavor, thread_state_t in_state, mach_msg_type_number_t in_stateCnt, thread_state_t out_state, mach_msg_type_number_t *out_stateCnt);

#define STACK_SIZE 0x8000
#define CODE_SIZE 512

char shellCode[] =
#if defined(__x86_64__)

"\x55"                            // push       rbp
"\x48\x89\xe5"                    // mov rbp,   rsp
"\x48\x83\xec\x10"                // sub rsp,   0x10
"\x48\xb8"                        // movabs     rax, _pthread_set_self
"PTHRDSS_"
"\xff\xd0"                        // call       rax
"\x48\x8d\x7d\xf8"                // lea        rdi,[rbp-0x8]
"\x31\xc0"                        // xor        eax,eax
"\x89\xc1"                        // mov        ecx,eax
"\x48\x8d\x15\x30\x00\x00\x00"    // lea        rdx,[rip+0x40]
"\x48\x89\xce"                    // mov        rsi,rcx
"\x48\xb8"                        // movabs     rax, pthread_create_from_mach_thread
"PTHRDCRT"
"\xff\xd0"                        // call       rax
"\x48\xb8"                        // movabs     rax, mach_thread_self
"THRDSELF"
"\xff\xd0"                        // call       rax
"\x48\x89\xc7"                    // mov        rdi, rax
"\x48\xb8"                        // movabs     rax, thread_terminate
"THRDTERM"
"\xff\xd0"                        // call       rax
"\x48\x83\xc4\x10"                // add        rsp, 0x10
"\x5d"                            // pop        rbp
"\xc3"                            // ret

"\x55"                            // push       rbp
"\x48\x89\xe5"                    // mov        rbp, rsp
"\x48\x83\xec\x10"                // sub        rsp, 0x10
"\xbe\x01\x00\x00\x00"            // mov        esi, 0x1
"\x48\x8d\x3d\x21\x00\x00\x00"    // lea        rdi, [rip+0x21]
"\x48\xb8"                        // movabs     rax, dlopen
"DLOPEN__"
"\xff\xd0"                        // call       rax
"\x48\x89\xc7"                    // mov        rdi, rax
"\x48\xb8"                        // movabs     rax, dlclose
"DLCLOSE_"
"\xff\xd0"                        // call       rax
"\x48\x83\xc4\x10"                // add        rsp,0x10
"\x5d"                            // pop        rbp
"\xc3"                            // ret


#else

"\xFF\xC3\x00\xD1"                // sub        sp, sp, #0x30
"\xFD\x7B\x02\xA9"                // stp        x29, x30, [sp, #0x20]
"\xFD\x83\x00\x91"                // add        x29, sp, #0x20
"\xc9\x02\x00\x10"                // adr        x9, #0x58           ; pointer to pthread_set_self
"\x29\x01\x40\xF9"                // ldr        x9, [x9]            ; dereference for value
"\x20\x01\x3F\xD6"                // blr        x9                  ; call pthread_set_self
"\xE0\x23\x00\x91"                // add        x0, sp, #0x8        ; stack pointer for arg0
"\x08\x00\x80\xD2"                // mov        x8, #0
"\xE8\x07\x00\xF9"                // str        x8, [sp, #0x8]
"\xE1\x03\x08\xAA"                // mov        x1, x8              ; NULL for arg1
"\xe2\x02\x00\x10"                // adr        x2, #0x5C           ; function pointer for arg2
"\xE2\x23\xC1\xDA"                // paciza     x2
"\xE3\x03\x08\xAA"                // mov        x3, x8              ; NULL for arg3
"\xc9\x01\x00\x10"                // adr        x9, #0x38           ; pointer to pthread_create_from_mach_thread
"\x29\x01\x40\xF9"                // ldr        x9, [x9]            ; dereference for value
"\x20\x01\x3F\xD6"                // blr        x9                  ; call pthrdcrt
"\xa9\x01\x00\x10"                // adr        x9, #0x34           ; pointer to thread_self
"\x29\x01\x40\xF9"                // ldr        x9, [x9]            ; dereference for value
"\x20\x01\x3F\xD6"                // blr        x9                  ; call thread_self
"\x89\x01\x00\x10"                // adr        x9, #0x30           ; pointer to thread_terminate
"\x29\x01\x40\xF9"                // ldr        x9, [x9]            ; dereference for value
"\x20\x01\x3F\xD6"                // blr        x9                  ; call thread_terminate
"\xFD\x7B\x42\xA9"                // ldp        x29, x30, [sp, #0x20]
"\xFF\xC3\x00\x91"                // add        sp, sp, #0x30
"\xC0\x03\x5F\xD6"                // ret
"PTHRDSS_"
"PTHRDCRT"
"THRDSELF"
"THRDTERM"

"\x7F\x23\x03\xD5"                // pacibsp
"\xFF\xC3\x00\xD1"                // sub        sp, sp, #0x30
"\xFD\x7B\x02\xA9"                // stp        x29, x30, [sp, #0x20]
"\xFD\x83\x00\x91"                // add        x29, sp, #0x20
"\x21\x00\x80\xD2"                // mov        x1, #1              ; RTLD_LAZY
"\xc0\x01\x00\x10"                // adr        x0, #0x38           ; char *libPath
"\x29\x01\x00\x10"                // adr        x9, #0x24
"\x29\x01\x40\xF9"                // ldr        x9, [x9]
"\x20\x01\x3F\xD6"                // blr        x9                  ; call dlopen
"\x09\x01\x00\x10"                // adr        x9, #0x20
"\x29\x01\x40\xF9"                // ldr        x9, [x9]
"\x20\x01\x3F\xD6"                // blr        x9                  ; call dlclose
"\xFD\x7B\x42\xA9"                // ldp        x29, x30, [sp, #0x20]
"\xFF\xC3\x00\x91"                // add        sp, sp, #0x30
"\xFF\x0F\x5F\xD6"                // retab
"DLOPEN__"
"DLCLOSE_"

#endif

"/Library/Application Support/MacEnhance/CorePlugins/PluginLoader.bundle/Contents/MacOS/PluginLoader\x00";

/* Globals */
dispatch_queue_t queue = 0;

static kern_return_t inject_task(task_t remoteTask) {
    kern_return_t kr = KERN_SUCCESS;
    
    mach_vm_address_t remoteStack = (vm_address_t)NULL;
    mach_vm_address_t remoteCode = (vm_address_t)NULL;
    
    //Allocate thread memory
    kr = mach_vm_allocate(remoteTask, &remoteCode, 3 * 0x4000, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        return kr;
    }
    
    remoteStack = remoteCode + 0x4000;
    
    kr = mach_vm_write(remoteTask,
                       remoteCode,
                       (vm_address_t)shellCode,
                       sizeof(shellCode));
    
    if (kr != KERN_SUCCESS) {
        return kr;
    }

    kr = vm_protect(remoteTask, remoteCode, 0x4000, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    kr = vm_protect(remoteTask, remoteStack, 2 * 0x4000, TRUE, VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        return kr;
    }
    
#if defined(__x86_64__)
    x86_thread_state64_t threadState = {0};
    x86_thread_state64_t machineThreadState = {0};
    thread_state_flavor_t flavor = x86_THREAD_STATE64;
    mach_msg_type_number_t stateCnt = x86_THREAD_STATE64_COUNT;
    mach_msg_type_number_t machineStateCnt = x86_THREAD_STATE64_COUNT;
#elif defined(__arm64__)
    struct arm_unified_thread_state threadState = {0};
    struct arm_unified_thread_state machineThreadState = {0};
    thread_state_flavor_t flavor = ARM_UNIFIED_THREAD_STATE;
    mach_msg_type_number_t stateCnt = ARM_UNIFIED_THREAD_STATE_COUNT;
    mach_msg_type_number_t machineStateCnt = ARM_UNIFIED_THREAD_STATE_COUNT;
#endif
    
#if defined(__x86_64__)
    threadState.__rdi = (uint64_t)(remoteStack);
    threadState.__rip = (uint64_t)(vm_address_t) remoteCode;
    threadState.__rsp = (uint64_t)(remoteStack + 0x4000);
#elif defined(__arm64__)
    threadState.ash.flavor = ARM_THREAD_STATE64;
    threadState.ash.count = ARM_THREAD_STATE64_COUNT;
    
    threadState.ts_64.__x[0] = (uint64_t)(remoteStack);
    __darwin_arm_thread_state64_set_pc_fptr(threadState.ts_64,
                                            ptrauth_sign_unauthenticated(ADDR_TO_PTR(remoteCode), ptrauth_key_asia, 0));

    __darwin_arm_thread_state64_set_sp(threadState.ts_64, (unsigned long)(remoteStack + 0x4000));
#endif

    thread_act_t remoteThread = MACH_PORT_NULL;
    kr = thread_create(remoteTask, &remoteThread);
    if(kr != KERN_SUCCESS) {
        fprintf(stderr, "Could not create thread: error %s\n", mach_error_string(kr));
        return kr;
    }
    
    if(_thread_convert_thread_state) {
        kr = _thread_convert_thread_state(remoteThread, 2, flavor, (thread_state_t)&threadState, stateCnt, (thread_state_t)&machineThreadState, &machineStateCnt);
        if(kr != KERN_SUCCESS) {
            fprintf(stderr, "Could not convert thread state: error %d %s\n", kr, mach_error_string(kr));
            return kr;
        }
    } else {
        machineThreadState = threadState;
    }
    
    kr = thread_set_state(remoteThread, flavor, (thread_state_t)&machineThreadState, machineStateCnt);
    if(kr != KERN_SUCCESS) {
        fprintf(stderr, "Could not set thread state: error %s\n", mach_error_string(kr));
        return kr;
    }
    
    kr = thread_resume(remoteThread);
    if(kr != KERN_SUCCESS) {
        fprintf(stderr, "Could not start thread: error %s\n", mach_error_string(kr));
        return kr;
    }

//    sleep(2);
//    mach_vm_deallocate(remoteTask, remoteCode, 3 * 0x4000);
    mach_port_deallocate(mach_task_self(), remoteThread);
    return kr;
}

void inject_sync(pid_t pid) {
    task_t task;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if(kr != KERN_SUCCESS) {
        return;
    }
        
    kr = inject_task(task);
    if(kr != KERN_SUCCESS) {
        fprintf(stderr, "Could not perform injection for %d\n", pid);
    }
    mach_port_deallocate(mach_task_self(), task);
}
    
void inject(pid_t pid) {
    dispatch_async(queue, ^{
        inject_sync(pid);
    });
}

static void symbolicate_shellcode() {
    uint64_t addrOfPthreadCreate = (uint64_t)dlsym(RTLD_DEFAULT, "pthread_create_from_mach_thread");
    uint64_t addrOfPthreadSetSelf = (uint64_t)dlsym(RTLD_DEFAULT, "_pthread_set_self");
    uint64_t addrOfThreadSelf = (uint64_t)mach_thread_self;
    uint64_t addrOfThreadTerminate = (uint64_t)thread_terminate;
    uint64_t addrOfDlopen = (uint64_t)dlopen;
    uint64_t addrOfDlclose = (uint64_t)dlclose;
    
#if defined(__arm64e__)
    addrOfPthreadCreate = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfPthreadCreate), ptrauth_key_function_pointer);
    addrOfPthreadSetSelf = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfPthreadSetSelf), ptrauth_key_function_pointer);
    addrOfThreadSelf = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfThreadSelf), ptrauth_key_function_pointer);
    addrOfThreadTerminate = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfThreadTerminate), ptrauth_key_function_pointer);
    addrOfDlopen = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfDlopen), ptrauth_key_function_pointer);
    addrOfDlclose = (uint64_t)ptrauth_strip(ADDR_TO_PTR(addrOfDlclose), ptrauth_key_function_pointer);
#endif
    
    char *possiblePatchLocation = (shellCode);
    for (int i = 0 ; i < sizeof(shellCode); i++) {
        possiblePatchLocation++;
        
        if (memcmp (possiblePatchLocation, "PTHRDCRT", 8) == 0) {
            memcpy(possiblePatchLocation, &addrOfPthreadCreate, sizeof(uint64_t));
        }
        
        if (memcmp (possiblePatchLocation, "PTHRDSS_", 8) == 0) {
            memcpy(possiblePatchLocation, &addrOfPthreadSetSelf, sizeof(uint64_t));
        }
        
        if (memcmp (possiblePatchLocation, "THRDSELF", 8) == 0) {
            memcpy(possiblePatchLocation, &addrOfThreadSelf, sizeof(uint64_t));
        }
        
        if (memcmp (possiblePatchLocation, "THRDTERM", 8) == 0) {
            memcpy(possiblePatchLocation, &addrOfThreadTerminate, sizeof(uint64_t));
        }
        
        if (memcmp(possiblePatchLocation, "DLOPEN__", 6) == 0) {
            memcpy(possiblePatchLocation, &addrOfDlopen, sizeof(uint64_t));
        }
        
        if (memcmp(possiblePatchLocation, "DLCLOSE_", 6) == 0) {
            memcpy(possiblePatchLocation, &addrOfDlclose, sizeof(uint64_t));
        }
    }
}

__attribute__((constructor))
static void ctor() {
    void *module = dlopen ("/usr/lib/system/libsystem_kernel.dylib", RTLD_LAZY);
    _thread_convert_thread_state = dlsym(module, "thread_convert_thread_state");
    dlclose (module);

    symbolicate_shellcode();
    queue = dispatch_queue_create("injectorQueue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_retain(queue);
}
