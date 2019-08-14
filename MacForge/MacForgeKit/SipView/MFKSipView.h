//
//  MFKSipView.h
//  MacForgeKit
//
//  Created by Wolfgang Baird on 8/11/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFKSipView : NSViewController

@property IBOutlet NSTextField *tv;
@property IBOutlet NSButton *confirmQuit;
@property IBOutlet NSButton *confirmReboot;
@property IBOutlet NSButton *confirm;

- (void)displayInWindow:(NSWindow*)window;

@end

NS_ASSUME_NONNULL_END
