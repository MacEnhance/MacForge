//
//  repopluginTable.m
//  MacPlus
//
//  Created by Wolfgang Baird on 3/24/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
long selectedRow;

@interface repopluginTable : NSTableView
{
    PluginManager *_sharedMethods;
}
@end

@interface repopluginTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  bundleName;
@property (weak) IBOutlet NSTextField*  bundleDescription;
@property (weak) IBOutlet NSTextField*  bundleInfo;
@property (weak) IBOutlet NSTextField*  bundleRepo;
@property (weak) IBOutlet NSImageView*  bundleImage;
@property (weak) IBOutlet NSImageView*  bundleImageInstalled;
@property (weak) IBOutlet NSImageView*  bundleIndicator;
@end

@implementation repopluginTable {
    NSArray *allPlugins;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [PluginManager sharedInstance];
    
    NSURL *dicURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/packages_v2.plist", repoPackages]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithContentsOfURL:dicURL];
    allPlugins = [dic allValues];
    selectedRow = 0;
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [allPlugins sortedArrayUsingDescriptors:sortDescriptors];
    allPlugins = sortedArray;
    
    return [allPlugins count];
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    repopluginTableCell *result = (repopluginTableCell*)[tableView makeViewWithIdentifier:@"psView" owner:self];
    NSDictionary* item = [[NSMutableDictionary alloc] initWithDictionary:[allPlugins objectAtIndex:row]];
    result.bundleName.stringValue = [item objectForKey:@"name"];
    NSString *shortDescription = @"";
    if ([item objectForKey:@"descriptionShort"] != nil) {
        if (![[item objectForKey:@"descriptionShort"] isEqualToString:@""])
            shortDescription = [item objectForKey:@"descriptionShort"];
    }
    if ([shortDescription isEqualToString:@""])
        shortDescription = [item objectForKey:@"description"];
    result.bundleDescription.stringValue = shortDescription;
    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"version"], [item objectForKey:@"package"]];
    result.bundleInfo.stringValue = bInfo;
    result.bundleDescription.toolTip = [item objectForKey:@"description"];
    result.bundleImage.image = [PluginManager pluginGetIcon:item];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];

    NSBundle *dank = [NSBundle bundleWithIdentifier:[item objectForKey:@"package"]];
    result.bundleImageInstalled.hidden = true;
    if (dank.bundlePath.length)
        if ([dank.bundlePath rangeOfString:[PluginManager MacEnhancePluginPaths][0]].length != 0)
            result.bundleImageInstalled.hidden = false;
    return result;
}

- (void)keyDown:(NSEvent *)theEvent {
    Boolean result = [myDelegate keypressed:theEvent];
    if (!result) [super keyDown:theEvent];
}

-(void)tableChange:(NSNotification *)aNotification {
    id sender = [aNotification object];
    selectedRow = [sender selectedRow];
    [pluginData sharedInstance].currentPlugin = nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}

@end

@implementation repopluginTableCell
@end
