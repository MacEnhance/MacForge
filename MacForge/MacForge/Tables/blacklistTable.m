//
//  blacklistTable.m
//  MacForge
//
//  Created by Wolfgang Baird on 7/29/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

@import AppKit;
#import "blacklistTable.h"

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
        NSMutableArray* sorted = [[NSMutableArray alloc] init];
        for (NSURL* url in urls) {
            if ([[url.path pathExtension] isEqualToString:@"app"]) {
                [sorted addObject:url.path];
                
                blPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacForgeHelper"];
                blDict = [blPrefs dictionaryRepresentation];
                NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[blPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
                
                NSString *path = url.path;
                NSBundle *bundle = [NSBundle bundleWithPath:path];
                NSString *bundleID = [bundle bundleIdentifier];
                if (![newBlacklist containsObject:bundleID]) {
                    NSLog(@"Adding key: %@", bundleID);
                    [newBlacklist addObject:bundleID];
                }

                
                [blPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
                [blPrefs synchronize];
                
                NSError *error;
                if (error)
                    NSLog(@"%@", error);
            }
        }
        if ([sorted count]) {
            [aTableView reloadData];
        }
    }
    return YES;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSUserDefaults *blPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacForgeHelper"];
    NSDictionary *blDict = [blPrefs dictionaryRepresentation];
    NSArray *tmpblacklist = [blDict objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
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
