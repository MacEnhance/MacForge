//
//  AppDelegate.h
//  purchaseValidationApp
//
//  Created by Wolfgang Baird on 9/20/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import Paddle;

#import <Cocoa/Cocoa.h>

#define NotificationCenter  [NSNotificationCenter defaultCenter]
#define Workspace           [NSWorkspace sharedWorkspace]
#define FileManager         [NSFileManager defaultManager]
#define Defaults            [NSUserDefaults standardUserDefaults]
#define paddleFldr          [[NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSAllDomainsMask, YES) firstObject] stringByAppendingString:@"/shared/macenhance"]
#define appSupport          [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject]

@interface AppDelegate : NSObject <PaddleDelegate, NSApplicationDelegate>

@end

