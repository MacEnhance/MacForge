//
//  MF_pluginPreferencesView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "MF_pluginPreferencesView.h"

@implementation MF_pluginPreferencesView

- (void)viewWillDraw{
    NSTableColumn *yourColumn = self.tv.tableColumns.lastObject;
    [yourColumn.headerCell setStringValue:@"Select a preference bundle"];
//    [self doAQuery];
    [_tv setDelegate:self];
    [_tv setDataSource:self];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 30;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSMutableArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Application Support/MacEnhance/Preferences" error:Nil].mutableCopy;
    NSMutableArray *res = NSMutableArray.new;
    for (NSString *file in dirs) {
        if ([file.pathExtension isEqualToString:@"bundle"])
            [res addObject:[@"/Library/Application Support/MacEnhance/Preferences/" stringByAppendingString:file]];
    }
    _pluginList = res.copy;
    return res.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    NSLog(@"%@", notification);
    
    // Fill container based on selection
    
    // TODO
    
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    NSImageView *img = [[NSImageView alloc] initWithFrame:CGRectMake(5, 3, 24, 24)];
    
    NSString *bundleID = @"";
    NSString *appPath = @"";
    appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];

    NSImage *appIMG = NSImage.new;
    NSString *appName = @"";
        
    if (appPath.length) {
        appIMG = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        if (appIMG == nil)
            appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        NSBundle *bundle = [NSBundle bundleWithPath:appPath];
        NSDictionary *info = [bundle infoDictionary];
        appName = [info objectForKey:@"CFBundleExecutable"];
    } else {
        appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        appName = bundleID;
    }

    NSTextField *appNameView = [[NSTextField alloc] initWithFrame:CGRectMake(32, 5, 200, 20)];
    appNameView.editable = NO;
    appNameView.bezeled = NO;
    [appNameView setSelectable:false];
    [appNameView setDrawsBackground:false];
    appNameView.stringValue = [_pluginList[row] lastPathComponent];

    [img setImage:appIMG];
    [result addSubview:appNameView];
    [result addSubview:img];

    return result;
}

@end
