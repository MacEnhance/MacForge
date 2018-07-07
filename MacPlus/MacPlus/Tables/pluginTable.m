//
//  pluginTable.m
//  TableTest
//
//  Created by Wolfgang Baird on 3/12/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import CoreImage;
#import "PluginManager.h"
#import "pluginData.h"
#import "MSPlugin.h"

extern NSMutableArray *confirmDelete;
extern NSMutableArray *pluginsArray;
NSInteger previusRow = -1;

@interface pluginTable : NSObject {
    PluginManager *_sharedMethods;
    pluginData *_pluginData;
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
@property (weak) IBOutlet MSPlugin*     pluginPlugin;
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
        _sharedMethods = [PluginManager sharedInstance];
    
    _pluginData = [pluginData sharedInstance];
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

- (NSImage*)colorInvert:(NSString*)named {
    NSImage *yourImage = [NSImage imageNamed:named];
    CIImage* ciImage = [[CIImage alloc] initWithData:[yourImage TIFFRepresentation]];
    CIFilter* filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setDefaults];
    [filter setValue:ciImage forKey:@"inputImage"];
    CIImage* output = [filter valueForKey:@"outputImage"];
    [output drawAtPoint:NSZeroPoint fromRect:NSRectFromCGRect([output extent]) operation:NSCompositeSourceOver fraction:1.0];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:output];
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
    return nsImage;
}

- (NSImage*)provideIMG:(int)position {
    if (self.imageArray == nil) {
        NSArray *images = @[[NSImage imageNamed:@"NSUser"],
                            [NSImage imageNamed:@"NSUserGroup"],
                            [self colorInvert:@"NSUser"],
                            [self colorInvert:@"NSUserGroup"]];
        self.imageArray = [[NSArray alloc] initWithArray:images];
    }
    
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"]) position += 2;
    NSImage *result = self.imageArray[position];
    return result;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    CustomTableCell *result = (CustomTableCell*)[tableView makeViewWithIdentifier:@"MyView" owner:self];
    MSPlugin *aBundle = [_tableContent objectAtIndex:row];
    
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
    
    result.pluginDescription.stringValue = aBundle.localDescription;
    result.pluginImage.image = [_pluginData fetch_icon:aBundle];
    
    // Return the result
    return result;
}

- (IBAction)pluginLocToggle:(id)sender {
    MSPlugin *plug = [_tableContent objectAtIndex:(long)[_tblView rowForView:sender]];
    NSString *name = plug.localName;
    NSString *path = plug.localPath;
    NSArray *paths = [PluginManager SIMBLPaths];
    NSInteger respath = 0;
    if (!plug.isUser) respath = 2;
    if (!plug.isEnabled) respath += 1;
    [_sharedMethods replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
}

- (IBAction)pluginToggle:(id)sender {
    MSPlugin *plug = [_tableContent objectAtIndex:(long)[_tblView rowForView:sender]];
    NSString *name = plug.localName;
    NSString *path = plug.localPath;
    NSArray *paths = [PluginManager SIMBLPaths];
    NSInteger respath = 0;
    if (plug.isUser) respath = 2;
    if (plug.isEnabled) respath += 1;
    [_sharedMethods replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
}

- (IBAction)pluginFinder:(id)sender {
    if (_tblView.selectedRow >= 0) {
        MSPlugin *plug = [_tableContent objectAtIndex:_tblView.selectedRow];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:plug.localPath];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
    }
}

- (IBAction)pluginDelete:(id)sender {
    if (_tblView.selectedRow >= 0) {
        MSPlugin *plug = [_tableContent objectAtIndex:_tblView.selectedRow];
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

