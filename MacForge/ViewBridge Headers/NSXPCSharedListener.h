//
//  NSXPCSharedListener.h
//  PrefLoader
//
//  Created by Jeremy on 5/22/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#ifndef NSXPCSharedListener_h
#define NSXPCSharedListener_h

@interface NSXPCSharedListener : NSObject
{
    NSMutableDictionary *_listeners;
    NSHashTable *_delegates;
    void *reserved;
}

+ (void)warmUpClassNamed:(id)arg1 inServiceNamed:(id)arg2;
+ (void)_failedToWarmUpClassNamed:(id)arg1 inServiceNamed:(id)arg2 dueTo:(id)arg3;
+ (id)sharedServiceListener;
+ (id)connectToService:(NSString *)service instanceIdentifier:(NSString *)identifier listener:(NSString *)listener queue:(id)q completion:(void (^)(NSXPCConnection*, NSError*))completionBlock;
+ (id)connectionForListenerNamed:(id)arg1 fromServiceNamed:(id)arg2;
+ (id)endpointForReply:(id)arg1 withListenerName:(id)arg2;
@property(retain) NSMutableDictionary *listeners; // @synthesize listeners=_listeners;
- (void)resumeSubService:(id)arg1;
- (void)resumeAdditionalService:(id)arg1;
- (void)resume;
- (BOOL)shouldAcceptNewConnection:(id)arg1 forListenerNamed:(id)arg2;
- (void)didAcceptNewConnection:(id)arg1;
- (id)listenerEndpointWithName:(id)arg1;
- (void)addListener:(id)arg1 withName:(id)arg2;
- (void)addDelegate:(id)arg1;
- (void)dealloc;

@end

#endif /* NSXPCSharedListener_h */
