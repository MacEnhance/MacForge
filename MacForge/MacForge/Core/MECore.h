//
//  MECore.h
//  MECore
//
//  Created by Wolfgang Baird on 5/8/20.
//

@import AppKit;
@import CocoaMarkdown;
@import AppCenterAnalytics;

@interface MF_FlippedView : NSView
@end

@interface MECoreSBButton : NSView

@property Boolean                   selected;
@property IBOutlet NSImageView*     buttonImage;
@property IBOutlet NSButton*        buttonClickArea;
@property IBOutlet NSButton*        buttonExtra;
@property IBOutlet NSView*          buttonHighlightArea;
@property IBOutlet NSTextField*     buttonLabel;
@property IBOutlet NSView*          linkedView;

@end

@interface MECore: NSObject

@property NSUInteger                macOS;
@property IBOutlet NSArray          *preferenceViews;
@property IBOutlet NSToolbarItem    *prefToolbar;
@property IBOutlet NSArray          *sidebarTopButtons;
@property IBOutlet NSArray          *sidebarBotButtons;
@property IBOutlet NSView           *mainView;
@property IBOutlet NSWindow         *mainWindow;
@property IBOutlet NSWindow         *prefWindow;
@property IBOutlet NSTextView       *changeLog;

+ (MECore*)sharedInstance;
+ (void)logInfo;
- (void)setupSidebar;
- (IBAction)selectView:(id)sender;
- (IBAction)selectPreference:(id)sender;
- (IBAction)selectAboutInfo:(id)sender;
- (void)setMainViewSubView:(NSView*)subview;
- (void)setViewSubViewWithScrollableView:(NSView*)view :(NSView*)subview ;
- (void)systemDarkModeChange:(NSNotification *)notif;

@end
