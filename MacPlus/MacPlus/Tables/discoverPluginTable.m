//
//  discoverTable.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 6/18/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "AppDelegate.h"
#import "shareClass.h"
#import "MSPlugin.h"
#import "pluginData.h"

extern AppDelegate *myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

NSArray *allPlugins;
NSArray *filteredPlugins;
NSString *textFilter;

@interface discoverPluginTable : NSTableView {
    shareClass *_sharedMethods;
    pluginData *_pluginData;
}
@property NSMutableArray *tableContent;
@property (weak) IBOutlet NSSearchField* pluginFilter;
@end

@interface discoverPluginTableCell : NSTableCellView <NSSearchFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTextField*  bundleName;
@property (weak) IBOutlet NSTextField*  bundleDescription;
@property (weak) IBOutlet NSTextField*  bundleInfo;
@property (weak) IBOutlet NSTextField*  bundleRepo;
@property (weak) IBOutlet NSImageView*  bundleImage;
@property (weak) IBOutlet NSImageView*  bundleImageInstalled;
@property (weak) IBOutlet NSImageView*  bundleIndicator;
@end

@implementation discoverPluginTable {
    
}

- (void)controlTextDidChange:(NSNotification *)obj{
    [self reloadData];
}

- (NSArray*)filterView:(NSArray*)original {
    NSString *filterText = _pluginFilter.stringValue;
    NSArray *result = original;
    if (filterText.length > 0) {
        result = [original filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(webName CONTAINS[cd] %@) OR (bundleID CONTAINS[cd] %@)", filterText, filterText]];
    }
    return result;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [shareClass alloc];
    
    static dispatch_once_t aToken;
    dispatch_once(&aToken, ^{
        self->_pluginData = [pluginData sharedInstance];
        [self->_pluginData fetch_repos];
    });
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *dank = [[NSMutableArray alloc] initWithArray:[_pluginData.repoPluginsDic allValues]];
    dank = [self filterView:dank];
    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
    
    return _tableContent.count;
}
    
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    discoverPluginTableCell *result = (discoverPluginTableCell*)[tableView makeViewWithIdentifier:@"dptView" owner:self];
    MSPlugin *item = [_tableContent objectAtIndex:row];
    
    result.bundleName.stringValue = item.webName;
    NSString *shortDescription = @"";
    if (item.webDescriptionShort != nil) {
        if (![item.webDescriptionShort isEqualToString:@""])
            shortDescription = item.webDescriptionShort;
    }
    if ([shortDescription isEqualToString:@""])
        shortDescription = item.webDescription;
    result.bundleDescription.stringValue = shortDescription;
    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", item.webVersion, item.bundleID];
    result.bundleInfo.stringValue = bInfo;
    result.bundleDescription.toolTip = item.webDescription;
        
    result.bundleImage.image = [_sharedMethods getbundleIcon:item.webPlist];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];

    NSBundle *dank = [NSBundle bundleWithIdentifier:item.bundleID];
    result.bundleImageInstalled.hidden = true;
    if (dank.bundlePath.length)
        if ([dank.bundlePath rangeOfString:@"/Library/Application Support/SIMBL/Plugins"].length != 0)
            result.bundleImageInstalled.hidden = false;
    return result;
}
    
- (void)keyDown:(NSEvent *)theEvent {
    Boolean result = [[shareClass sharedInstance] keypressed:theEvent];
    if (!result) [super keyDown:theEvent];
}
    
-(void)tableChange:(NSNotification *)aNotification {
    id sender = [aNotification object];
    MSPlugin *item = [_tableContent objectAtIndex:[sender selectedRow]];
    [pluginData sharedInstance].currentPlugin = item;
}
    
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}
    
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification {
    [self tableChange:aNotification];
}
    
@end

@implementation discoverPluginTableCell
@end
