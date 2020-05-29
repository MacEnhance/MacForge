@import Cocoa;
#import "NSViewBridge.h"

@interface NSViewServiceBridge : NSViewBridge

@property (readonly) NSViewServiceMarshal *viewServiceMarshal;
@property (readonly) void *auditToken;
@property (readonly) int processIdentifier;

- (instancetype)initWithServiceMarshal:(NSViewServiceMarshal *)marshal;

- (void)registerKey:(NSString *)key defaultObject:(id)obj owner:(NSViewBridgeOwnerType)ownerType;

@end

// Use this in the service XPC side.
@interface NSServiceViewController : NSViewController

+ (id)serviceBundle;
+ (void)deferBlockOntoMainThread:(id)arg1;
+ (void)withHostProcessIdentifier:(int)arg1 invoke:(id)arg2;
+ (id)serviceViewControllerForWindow:(NSWindow *)window;
+ (id)listenerEndpoint;
+ (BOOL)setAccessibilityParent:(long long)arg1 forWindow:(id)arg2;
+ (BOOL)currentAppIsViewService;
+ (id)hostAppDescription:(int)arg1;
+ (unsigned int)_windowForContextID:(unsigned int)arg1 fromViewService:(int)arg2 error:(id *)arg3;
+ (unsigned int)declinedEventMask;

@property NSViewServiceMarshal *marshal;
@property (readonly) NSInteger hostSDKVersion;
@property (readonly) NSWindow *serviceWindow;
@property (readonly) NSInteger callsToSetViewCount;
@property (readonly) BOOL mostRecentCallToSetViewWasNonNil;
@property (readonly) BOOL valid;
@property (readonly) NSViewServiceBridge *bridge;
@property (readonly) CGSize sizeHint;
@property (readonly) NSString *remoteViewIdentifier;
@property (readonly) BOOL adjustLayoutInProgress;
@property (readonly) CGSize remoteViewSize;
@property (readonly) BOOL makesExplicitResizeRequests;
@property (readonly) BOOL allowsImplicitResizeRequests;
@property (readonly) BOOL allowsWindowFrameOriginChanges;

- (instancetype)initWithWindow:(id)arg1;

- (id)remoteViewControllerProxyWithErrorHandler:(id)arg1;
- (id)remoteViewControllerProxy;
- (id)exportedObject;
- (id)exportedInterface;
- (id)remoteViewControllerInterface;

- (NSUInteger)awakeFromRemoteView;
- (void)advanceToRunPhase;
- (void)retreatToConfigPhase;

- (BOOL)invalid;
- (void)invalidate;

- (void)_windowFrameWillChange;
- (void)_windowFrameDidChange;
- (void)_didDisassociateFromHostWindow;
- (void)_didAssociateWithHostWindow;
- (BOOL)_shouldNormalizeAppearance;
- (CGRect)_serviceWindowFrameForRemoteViewFrame:(CGRect)arg1;
- (void)_setHostSDKVersion:(NSInteger)arg1;
- (void)_endPrivateEventLoop;
- (void)hostWindowReceivedEventType:(NSUInteger)arg1;
- (void)setAccessoryViewSize:(CGSize)arg1;
- (void)forgetAccessoryView;
- (void)_invalidateRendezvousWindowControllers;
- (void)childWindowDidInvalidate:(id)arg1 dueToError:(id)arg2;
- (void)_retainMarshal;
- (BOOL)isLayerCentric;
- (void)whileMouseIsDisassociatedFromMouseCursorPosition:(id)arg1;
- (void)associateMouseAndMouseCursorPosition:(BOOL)arg1 completion:(id)arg2;
- (id)requestResize:(CGSize)arg1 animation:(id)arg2 completion:(id)arg3;
- (id)_requestResize:(CGSize)arg1 hostShouldAnimate:(BOOL)arg2 animation:(id)arg3 completion:(id)arg4;
- (BOOL)remoteViewSizeChanged:(CGSize)arg1 transaction:(id)arg2;
- (BOOL)remoteViewSizeChanged:(CGSize)arg1 transactions:(id)arg2;
- (void)adjustLayout:(id)arg1 animation:(id)arg2 completion:(id)arg3;
- (void)_animateLayout:(id)arg1 forWindow:(id)arg2 withNewFittingSize:(CGSize)arg3 completion:(id)arg4;
- (void)defaultResizeBehavior;
- (BOOL)_explicitSizeRequestInhibitsImplicitSizeRequests;
- (NSUInteger)filterStyleMask:(NSUInteger)arg1;
- (NSUInteger)acceptableStyleMask;
- (id)leastRecentError;
- (void)errorOccurred:(id)arg1;
- (void)deferBlockOntoMainThread:(id)arg1;
- (void)withHostContextInvoke:(id)arg1;
- (unsigned int)declinedEventMask;

@end
