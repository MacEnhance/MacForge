//
//  discoverTable.m
//  MacPlus
//
//  Created by Wolfgang Baird on 6/18/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "AppDelegate.h"
#import "PluginManager.h"
#import "MSPlugin.h"
#import "pluginData.h"

extern AppDelegate *myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

NSArray *allPlugins;
NSArray *filteredPlugins;
NSString *textFilter;

@interface discoverPluginTable : NSTableView {
    PluginManager *_sharedMethods;
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

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [PluginManager sharedInstance];
    
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

//- (NSMenu *)menuForEvent:(NSEvent *)event {
//    NSMenu *booty = [[NSMenu alloc] init];
//    [booty setTitle:@"Ayyy"];
//    [booty addItem:[NSMenuItem.alloc initWithTitle:@"Install" action:nil keyEquivalent:@""]];
//    [booty addItem:[NSMenuItem.alloc initWithTitle:@"Delete" action:nil keyEquivalent:@""]];
//    return booty;
//}

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
    
//    NSSize titleSize = [item.webName sizeWithAttributes:@{NSFontAttributeName:result.bundleName.font}];
//    int start = result.bundleName.frame.origin.x + 10 + titleSize.width;
//    NSButton *buy = [[NSButton alloc] initWithFrame:CGRectMake(start, result.bundleName.frame.origin.y, 50, 16)];
//    [buy setWantsLayer:true];
//    [buy setBordered:false];
//    if (![item.webPrice isEqualToString:@"Free"] && ![item.webPrice isEqualToString:@"$0.00"]) {
//        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.0 green:0.4 blue:1.0 alpha:1.0].CGColor];
//        [buy setTitle:@"Buy"];
//    } else {
//        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0].CGColor];
//        [buy setTitle:@"Install"];
//    }
//    [buy.layer setCornerRadius:8];
//    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
//    [style setAlignment:NSCenterTextAlignment];
//    NSDictionary *attrsDictionary  = [NSDictionary dictionaryWithObjectsAndKeys:
//                                      NSColor.whiteColor, NSForegroundColorAttributeName,
//                                      buy.font, NSFontAttributeName,
//                                      style, NSParagraphStyleAttributeName, nil];
//    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:buy.title attributes:attrsDictionary];
//    [buy setAttributedTitle:attrString];
//    [result addSubview:buy];
    
    result.bundleImage.image = [PluginManager pluginGetIcon:item.webPlist];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];

    // Check if installed
    Boolean hideCheckmark = true;
    NSString *a = [NSString stringWithFormat:@"/Library/Application Support/SIMBL/Plugins/%@.bundle", item.webName];
    NSString *b = [NSString stringWithFormat:@"/Users/%@/Library/Application Support/SIMBL/Plugins/%@.bundle", NSUserName(), item.webName];
    if ([FileManager fileExistsAtPath:a] || [FileManager fileExistsAtPath:b]) hideCheckmark = false;
    result.bundleImageInstalled.hidden = hideCheckmark;

//    NSPoint p = CGPointMake(result.bundleIndicator.frame.origin.x - 40, result.bundleIndicator.frame.origin.y + 8);
//    [result.bundleImageInstalled setFrameOrigin:p];
//    [result.bundleImageInstalled setAutoresizingMask:NSViewMinXMargin];

//    NSBundle *dank = [NSBundle bundleWithIdentifier:item.bundleID];
//    result.bundleImageInstalled.hidden = true;
//    if (dank.bundlePath.length)
//        if ([dank.bundlePath rangeOfString:@"/Library/Application Support/SIMBL/Plugins"].length != 0)
    
    return result;
}
    
- (void)keyDown:(NSEvent *)theEvent {
    Boolean result = [myDelegate keypressed:theEvent];
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
