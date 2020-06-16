//
//  main.m
//  PreferenceLoader
//
//  Created by Jeremy on 5/25/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferenceLoader.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@property (assign) NSXPCListener *listener;
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PreferenceLoaderProtocol)];
    PreferenceLoader *exportedObject = [PreferenceLoader new];
    newConnection.exportedObject = exportedObject;
    
    [newConnection resume];

    return YES;
}

@end

int main(int argc, const char *argv[])
{
    NSXPCListener *anonListener = [NSXPCListener anonymousListener];
    NSXPCSharedListener *sharedListener = [NSXPCSharedListener sharedServiceListener];
    ServiceDelegate *delegate = [ServiceDelegate new];
    [anonListener setDelegate:delegate];
    [delegate setListener:anonListener];
    [sharedListener addListener:anonListener withName:@"com.macenhance.MacForge"];
    NSViewServiceApplicationMain();
    return 0;
}
