//
//  blacklistTable.m
//  MacForge
//
//  Created by Wolfgang Baird on 7/29/18.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
#import "blacklistTable.h"
#import "MF_BlacklistManager.h"

NSUserDefaults *blPrefs;
NSDictionary *blDict;

@implementation blacklistTableCell
@end

@implementation blacklistTable

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationCopy;
}

// Handle drag and drop
- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray* urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        [MF_BlacklistManager addBlacklistItems:urls];
        [aTableView reloadData];
    }
    return YES;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSUserDefaults *blPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.macenhance.MacForgeHelper"];
    NSDictionary *blDict = [blPrefs dictionaryRepresentation];
    NSArray *tmpblacklist = [blDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI", @"org.w0lf.cDockHelper", @"com.macenhance.MacForge", @"com.macenhance.MacForgeHelper", @"com.macenhance.purchaseValidationApp"];
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:tmpblacklist];
    [newlist removeObjectsInArray:alwaysBlaklisted];
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
    NSImage *appIMG;
    NSString *appName;
    
    if (appPath != nil) {
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
    appNameView.stringValue = appName;
    [img setImage:appIMG];
    [result addSubview:appNameView];
    [result addSubview:img];
    result.bundleID = bundleID;
    return result;
}

@end
