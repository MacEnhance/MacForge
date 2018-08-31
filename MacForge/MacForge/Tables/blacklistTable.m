//
//  blacklistTable.m
//  MacPlus
//
//  Created by Wolfgang Baird on 7/29/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

@import AppKit;
#import "blacklistTable.h"

@implementation blacklistTableCell
@end

@implementation blacklistTable

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSUserDefaults *sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacForgeHelper"];
    NSDictionary *sharedDict = [sharedPrefs dictionaryRepresentation];
    NSArray *tmpblacklist = [sharedDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI"];
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:tmpblacklist];
    for (NSString *app in alwaysBlaklisted)
        if (![tmpblacklist containsObject:app])
            [newlist addObject:app];
    _blackList = newlist;
    return _blackList.count;
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    blacklistTableCell *result = [[blacklistTableCell alloc] initWithFrame:CGRectMake(0, 30, 100, 15)];
//    blacklistTableCell *result = (blacklistTableCell*)[[NSView alloc] initWithFrame:CGRectMake(0, 25, 100, 15)];
    NSImageView *img = [[NSImageView alloc] initWithFrame:CGRectMake(5, 3, 24, 24)];
    NSString *bundleID = _blackList[row];
    NSString *appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    NSImage *appIMG = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
    if (appIMG == nil)
        appIMG = [NSImage imageNamed:NSImageNameApplicationIcon];
    NSBundle *bundle = [NSBundle bundleWithPath:appPath];
    NSDictionary *info = [bundle infoDictionary];
    NSString *appName = [info objectForKey:@"CFBundleExecutable"];
    NSTextField *appNameView = [[NSTextField alloc] initWithFrame:CGRectMake(32, 5, 200, 20)];
    appNameView.editable = NO;
    appNameView.bezeled = NO;
    [appNameView setSelectable:false];
    [appNameView setDrawsBackground:false];
    appNameView.stringValue = appName;
    [img setImage:appIMG];
    [result addSubview:img];
    [result addSubview:appNameView];
    result.bundleID = bundleID;
    return result;
}

@end
