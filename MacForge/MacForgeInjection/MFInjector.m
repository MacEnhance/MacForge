//
//  Injector.m
//  Injector
//
//  Created by Wolfgang Baird on 8/8/12.
//  Copyright (c) 2020 MacEnhance. All rights reserved.
//

#import "MFInjector.h"
#import "UniversalInj.h"

#import <dlfcn.h>
#import <mach/mach_error.h>

@interface MFInjector ()
@property (atomic, strong, readwrite) NSXPCListener *listener;
@end

@implementation MFInjector

- (id)init {
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = [[NSXPCListener alloc] initWithMachServiceName:@"com.macenhance.MacForge.Injector.mach"];
        self.listener.delegate = self;
        // [self redirectLogToDocuments];
    }
    return self;
}

- (void)run {
    [self.listener resume];
    [[NSRunLoop currentRunLoop] run];
}

- (void)redirectLogToDocuments {
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupport = [[allPaths objectAtIndex:0] stringByAppendingPathComponent:@"MacForge"];
    if (![NSFileManager.defaultManager fileExistsAtPath:appSupport isDirectory:nil])
        [NSFileManager.defaultManager createDirectoryAtPath:appSupport withIntermediateDirectories:true attributes:nil error:nil];
    NSString *pathForLog = [appSupport stringByAppendingPathComponent:@"Injector.log"];
    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

- (void)folderSetup:(void (^)(mach_error_t))reply {
    NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInt:0777], NSFilePosixPermissions,
                            [NSNumber numberWithInt:0], NSFileGroupOwnerAccountID,
                            [NSNumber numberWithInt:0], NSFileOwnerAccountID, nil];

    NSArray *folders = @[@"CorePlugins", @"Docklets", @"Plugins", @"Plugins (Disabled)", @"Preferences", @"Themes"];
    NSError *fileError;
    NSFileManager *man = NSFileManager.defaultManager;
    for (NSString* filename in folders) {
        NSString *folderpath = [@"/Library/Application Support/MacEnhance" stringByAppendingPathComponent:filename];
        if (![man fileExistsAtPath:folderpath isDirectory:nil]) {
            [man createDirectoryAtPath:folderpath withIntermediateDirectories:true attributes:attrib error:&fileError];
            [man setAttributes:@{ NSFilePosixPermissions : @0777 } ofItemAtPath:folderpath error:&fileError];
        }
    }
    reply(0);
}

- (void)installFramework:(NSString *)frameworkPath atlocation:(NSString*)frameworkDestinationPath withReply:(void (^)(mach_error_t))reply {
    NSError *fileError;
    if ([[NSFileManager defaultManager] fileExistsAtPath:frameworkDestinationPath])
        [[NSFileManager defaultManager] removeItemAtPath:frameworkDestinationPath error:&fileError];
    [[NSFileManager defaultManager] copyItemAtPath:frameworkPath toPath:frameworkDestinationPath error:&fileError];
    reply((int)fileError.code);
}

//- (void)injectBundle:(const char *)bundlePackageFileSystemRepresentation inProcess:(pid_t)pid withReply:(void (^)(mach_error_t))reply {
//    inject_sync(pid, bundlePackageFileSystemRepresentation);
////    inject(pid, bundlePackageFileSystemRepresentation);
//    reply(0);
//}

- (void)injectProcess:(pid_t)pid {
    inject(pid);
}


#pragma mark XPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MFInjectorProtocol)];
    newConnection.exportedObject = self;
    [newConnection setInvalidationHandler:^{
        exit(0);
    }];
    
    [newConnection setInterruptionHandler:^{
        exit(0);
    }];
    [newConnection resume];
    return YES;
}

@end
