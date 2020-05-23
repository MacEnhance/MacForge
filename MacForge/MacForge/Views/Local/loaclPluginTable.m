//
//  pluginTable.m
//  TableTest
//
//  Created by Wolfgang Baird on 3/12/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import CoreImage;
#import "MF_PluginManager.h"
#import "MF_repoData.h"
#import "MF_Plugin.h"

extern NSMutableArray *pluginsArray;
NSInteger previusRow = -1;

@interface pluginTable : NSObject {
    MF_PluginManager *_sharedMethods;
    MF_repoData *_pluginData;
    NSArray *image_array;
    NSImage *user;
    NSImage *group;
}
@property (weak) IBOutlet NSTableView*  tblView;
@property NSMutableArray *tableContent;
@property NSArray *imageArray;
@property (weak) IBOutlet NSSearchField* pluginFilter;
@property (weak) IBOutlet NSButton*     pluginDelete;
@property (weak) IBOutlet NSButton*     pluginFinder;
@property (weak) IBOutlet NSButton*     pluginWeb;
@end

@interface CustomTableCell : NSTableCellView <NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSButton*     pluginUserLoc;
@property (weak) IBOutlet NSButton*     pluginStatus;
@property (weak) IBOutlet NSTextField*  pluginName;
@property (weak) IBOutlet NSTextField*  pluginDescription;
@property (weak) IBOutlet NSImageView*  pluginImage;
@property (weak) IBOutlet NSString*     pluginID;
@property (weak) IBOutlet MF_Plugin*     pluginPlugin;
@end

@implementation pluginTable

- (void)controlTextDidChange:(NSNotification *)obj{
    [_tblView reloadData];
}

- (NSArray*)filterView:(NSArray*)original {
    NSString *filterText = _pluginFilter.stringValue;
    NSArray *result = original;
    if (filterText.length > 0) {
        result = [original filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(localName CONTAINS[cd] %@) OR (bundleID CONTAINS[cd] %@)", filterText, filterText]];
    }
    return result;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [MF_PluginManager sharedInstance];
    
    _pluginData = [MF_repoData sharedInstance];
    [_pluginData fetch_local];
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"localName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *dank = [[NSMutableArray alloc] initWithArray:[_pluginData.localPluginsDic allValues]];
    dank = [self filterView:dank];
    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
    
    return _tableContent.count;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray* urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        NSMutableArray* sorted = [[NSMutableArray alloc] init];
        for (NSURL* url in urls) {
            if ([[url.path pathExtension] isEqualToString:@"bundle"]) {
                [sorted addObject:url.path];
            }
        }
        if ([sorted count]) {
            NSArray* installArray = [NSArray arrayWithArray:sorted];
            [_sharedMethods installBundles:installArray];
        }
    }
    return YES;
}

- (NSImage*)provideIMG:(int)position {
    if (self.imageArray == nil) {
        if (user == nil) {
            user = [NSImage imageNamed:NSImageNameUser];
            [user setTemplate:true];
        }
        if (group == nil) {
            group = [NSImage imageNamed:NSImageNameUserGroup];
            [group setTemplate:true];
        }
        if (image_array == nil) {
            image_array = @[user, group];
        }
//        NSImage *user = [NSImage imageNamed:NSImageNameUser];
//        [user setTemplate:true];
//        NSImage *group = [NSImage imageNamed:NSImageNameUserGroup];
//        [group setTemplate:true];
//        NSArray *images = @[user, group];
//        self.imageArray = [[NSArray alloc] initWithArray:images];
    }
    return image_array[position];
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomTableCell *result = (CustomTableCell*)[tableView makeViewWithIdentifier:@"MyView" owner:self];
    MF_Plugin *aBundle = [_tableContent objectAtIndex:row];
    
    result.pluginName.stringValue = aBundle.localName;
    if([aBundle.localPath length]) {
        result.pluginPlugin = aBundle;
        if (aBundle.isEnabled) {
            [result.pluginStatus setState:NSOnState];
        } else {
            [result.pluginStatus setState:NSOffState];
        }
        if (aBundle.isUser) {
            [result.pluginUserLoc setImage:[self provideIMG:0]];
        } else {
            [result.pluginUserLoc setImage:[self provideIMG:1]];
        }
    }
    
    result.pluginImage.image = [_pluginData fetch_icon:aBundle];
    result.pluginDescription.stringValue = aBundle.localDescription;
//    result.pluginImage.animates = YES;
//    result.pluginImage.image = [NSImage imageNamed:@"loading_mini.gif"];
//    result.pluginImage.canDrawSubviewsIntoLayer = YES;
//    [result.superview setWantsLayer:YES];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSImage *appIcon = [self->_pluginData fetch_icon:aBundle];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            //Wants to update UI or perform any task on main thread.
//            result.pluginImage.image = appIcon;
//        });
//    });
//
    
    // Return the result
    return result;
}

- (IBAction)pluginLocToggle:(id)sender {
    MF_Plugin *plug = [_tableContent objectAtIndex:(long)[_tblView rowForView:sender]];
    NSString *name = plug.localName;
    NSString *path = plug.localPath;
    NSArray *paths = [MF_PluginManager MacEnhancePluginPaths];
    NSInteger respath = 0;
    if (!plug.isUser) respath = 2;
    if (!plug.isEnabled) respath += 1;
    [_sharedMethods replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
}

- (IBAction)pluginToggle:(id)sender {
    MF_Plugin *plug = [_tableContent objectAtIndex:(long)[_tblView rowForView:sender]];
    NSString *name = plug.localName;
    NSString *path = plug.localPath;
    NSArray *paths = [MF_PluginManager MacEnhancePluginPaths];
    NSInteger respath = 0;
    if (plug.isUser) respath = 2;
    if (plug.isEnabled) respath += 1;
    [_sharedMethods replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
}

- (IBAction)pluginFinder:(id)sender {
    if (_tblView.selectedRow >= 0) {
        MF_Plugin *plug = [_tableContent objectAtIndex:_tblView.selectedRow];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:plug.localPath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
    }
}

- (IBAction)pluginDelete:(id)sender {
    if (_tblView.selectedRow >= 0) {
        MF_Plugin *plug = [_tableContent objectAtIndex:_tblView.selectedRow];
        NSURL* url = [NSURL fileURLWithPath:plug.localPath];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}

-(void)tableChange:(NSNotification *)aNotification {
    if (_tblView.selectedRow >= 0) {
        [_pluginFinder setEnabled:true];
        [_pluginDelete setEnabled:true];
    } else {
        [_pluginFinder setEnabled:false];
        [_pluginDelete setEnabled:false];
    }
}

@end

@implementation CustomTableCell
@end

