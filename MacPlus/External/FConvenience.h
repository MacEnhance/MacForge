// Frequently used macros for uncluttering things (Import in your PCH)
#define _Log(prefix, ...) fprintf(stderr, prefix "%s[%u] %s: %s\n", \
    [[[NSProcessInfo processInfo] processName] UTF8String], \
    getpid(),\
    [[NSString stringWithFormat:@"%10.15s:%u", \
                                [[@(__FILE__) lastPathComponent] UTF8String], \
                                __LINE__] UTF8String],\
    [[NSString stringWithFormat:__VA_ARGS__] UTF8String])

#define Log(...) _Log("V ", ##__VA_ARGS__) // V: Verbose

#define _CheckOSErr(shouldAssert, error, fmt, ...) do { \
    OSStatus __err = (error); \
    if(__err) { \
        Log(@"OSErr %d: " fmt, (int)__err, ##__VA_ARGS__); \
        assert(!shouldAssert); \
    } \
} while(0)

#ifdef DEBUG
    #define CrashHere()   { *(int *)0 = 0xDEADBEEF; }
    #define DebugLog(...) _Log("D ", ##__VA_ARGS__) // D: Debug
    #define CheckOSErr(err, fmt, ...) _CheckOSErr(true, err, fmt, ##__VA_ARGS__)
#else
    #define CrashHere()
    #define DebugLog(...) 
    #define CheckOSErr(err, fmt, ...) _CheckOSErr(false, err, fmt, ##__VA_ARGS__)
#endif

#define GlobalQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define MainQueue dispatch_get_main_queue()

#define Once(...) do { \
    static dispatch_once_t __token; \
    dispatch_once(&__token, ##__VA_ARGS__); \
} while(0)
#define Async(...) dispatch_async(GlobalQueue, ##__VA_ARGS__)
#define AsyncOnMain(...) dispatch_async(MainQueue, ##__VA_ARGS__)

#define NotificationCenter [NSNotificationCenter defaultCenter]
#define Workspace   [NSWorkspace sharedWorkspace]
#define FileManager [NSFileManager defaultManager]
#define Defaults    [NSUserDefaults standardUserDefaults]

#define unless(...) if(!(__VA_ARGS__))
#define until(...)  while(!(__VA_ARGS__))

#define CLAMP(val, min, max) MAX((min), MIN((val), (max)))

//@interface NSUserDefaults (Subscripts)
//- (id)objectForKeyedSubscript:(id)aKey;
//- (void)setObject:(id)aObj forKeyedSubscript:(id)aKey;
//@end

