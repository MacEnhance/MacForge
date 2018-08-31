//
//  discoverTable.m
//  MacPlus
//
//  Created by Wolfgang Baird on 6/18/17.
//  Copyright © 2017 Wolfgang Baird. All rights reserved.
//

@import AppKit;
@import QuartzCore;
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
@property NSArray *localPlugins;
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
    NSString *filter = @"(webName CONTAINS[cd] %@) OR (bundleID CONTAINS[cd] %@) OR (webTarget CONTAINS[cd] %@)";
    if (filterText.length > 0) {
        result = [original filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:filter, filterText, filterText, filterText]];
    }
    return result;
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [PluginManager sharedInstance];
    
    // Fetch repo content
    static dispatch_once_t aToken;
    dispatch_once(&aToken, ^{
        self->_pluginData = [pluginData sharedInstance];
        [self->_pluginData fetch_repos];
    });
    
    // Sort table by name
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *dank = [[NSMutableArray alloc] initWithArray:[_pluginData.repoPluginsDic allValues]];
    dank = [self filterView:dank];
    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
    
    // Fetch our local content too
    _localPlugins = [_sharedMethods getInstalledPlugins].allKeys;
    
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
//    int xPos = result.bundleName.frame.origin.x + 10 + titleSize.width;
//    int yPos = result.bundleName.frame.origin.y;
    
//    [self add_interaction_button:result :item];

    // Check if installed
//    Boolean hideCheckmark = true;
//    NSString *a = [NSString stringWithFormat:@"/Library/Application Support/SIMBL/Plugins/%@.bundle", item.webName];
//    NSString *b = [NSString stringWithFormat:@"/Users/%@/Library/Application Support/SIMBL/Plugins/%@.bundle", NSUserName(), item.webName];
//    if ([FileManager fileExistsAtPath:a] || [FileManager fileExistsAtPath:b]) hideCheckmark = false;
//    result.bundleImageInstalled.hidden = hideCheckmark;

//    NSPoint p = CGPointMake(result.bundleIndicator.frame.origin.x - 40, result.bundleIndicator.frame.origin.y + 8);
//    [result.bundleImageInstalled setFrameOrigin:p];
//    [result.bundleImageInstalled setAutoresizingMask:NSViewMinXMargin];

//    NSBundle *dank = [NSBundle bundleWithIdentifier:item.bundleID];
//    result.bundleImageInstalled.hidden = true;
//    if (dank.bundlePath.length)
//        if ([dank.bundlePath rangeOfString:@"/Library/Application Support/SIMBL/Plugins"].length != 0)
    
    if ([_localPlugins containsObject:item.bundleID]) {
        result.bundleImageInstalled.hidden = false;
        [result.bundleImageInstalled setImageScaling:NSImageScaleProportionallyUpOrDown];
    }
    
    result.bundleImage.image = [PluginManager pluginGetIcon:item.webPlist];
    [result.bundleImage.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    return result;
}

- (void)press_interaction_button:(id)sender {
    NSLog(@"Test");
}

- (void)add_interaction_button:(discoverPluginTableCell*)result :(MSPlugin*)item {
    int xPos = result.frame.size.width - 100;
    int yPos = result.frame.size.height / 2 - 10;
    NSButton *buy = [[NSButton alloc] initWithFrame:CGRectMake(xPos, yPos, 70, 20)];
    [buy setWantsLayer:true];
    [buy setBordered:false];
    [buy setTarget:self];
    [buy setAction:@selector(press_interaction_button:)];
    if (item.webPaid) {
        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1.0].CGColor];
        //        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.0 green:0.4 blue:1.0 alpha:1.0].CGColor];
        //        CAGradientLayer *gradient = [CAGradientLayer layer];
        //        gradient.frame            = buy.bounds;
        //        gradient.colors           = [NSArray arrayWithObjects:(id)[NSColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0].CGColor, (id)[NSColor colorWithRed:0.0 green:0.4 blue:1.0 alpha:1.0].CGColor, nil];
        //        [buy.layer setBackgroundColor:NSColor.clearColor.CGColor];
        //        [buy.layer insertSublayer:gradient atIndex:0];
        [buy setTitle:item.webPrice];
        //        [buy setTitle:@"Paid"];
    } else {
        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.9 green:0.9 blue:0.95 alpha:1.0].CGColor];
        //        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0].CGColor];
        //        CAGradientLayer *gradient = [CAGradientLayer layer];
        //        gradient.frame            = buy.bounds;
        //        gradient.colors           = [NSArray arrayWithObjects:(id)[NSColor colorWithRed:0.4 green:0.8 blue:0.4 alpha:1.0].CGColor, (id)[NSColor colorWithRed:0.2 green:1.0 blue:0.2 alpha:1.0].CGColor, nil];
        //        [buy.layer setBackgroundColor:NSColor.clearColor.CGColor];
        //        [buy.layer insertSublayer:gradient atIndex:0];
        [buy setTitle:@"Install"];
    }
    if ([_localPlugins containsObject:item.bundleID]) {
        //        [buy.layer setBackgroundColor:[NSColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0].CGColor];
        //        NSGradient *g = [NSGradient.alloc initWithStartingColor:NSColor.redColor endingColor:NSColor.blueColor];
        [buy setTitle:@"OPEN"];
        //        CGRect frm = CGRectMake(buy.frame.origin.x - 20, buy.frame.origin.y, 16, 16);
        //        NSImageView *v = [[NSImageView alloc] initWithFrame:frm];
        //        [v setImage:[NSImage imageNamed:@"checkmark"]];
        //        [result addSubview:v];
        result.bundleImageInstalled.hidden = false;
        Boolean hideCheckmark = true;
        NSString *a = [NSString stringWithFormat:@"/Library/Application Support/SIMBL/Plugins/%@.bundle", item.webName];
        NSString *b = [NSString stringWithFormat:@"/Users/%@/Library/Application Support/SIMBL/Plugins/%@.bundle", NSUserName(), item.webName];
        if ([FileManager fileExistsAtPath:a] || [FileManager fileExistsAtPath:b]) hideCheckmark = false;
        if (hideCheckmark) {
            [buy setTitle:@"Enable"];
            //            [result.bundleImageInstalled setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        } else {
            [buy setTitle:@"Disable"];
            //            [result.bundleImageInstalled setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        }
        
        [result.bundleImageInstalled setImageScaling:NSImageScaleProportionallyUpOrDown];
    }
    [buy setAutoresizingMask:NSViewMinXMargin];
    [buy.layer setCornerRadius:10];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:NSCenterTextAlignment];
    NSColor *txtColor = [NSColor colorWithRed:0.0 green:0.4 blue:1.0 alpha:1.0];
    NSDictionary *attrsDictionary  = [NSDictionary dictionaryWithObjectsAndKeys:
                                      txtColor, NSForegroundColorAttributeName,
                                      buy.font, NSFontAttributeName,
                                      style, NSParagraphStyleAttributeName, nil];
    NSAttributedString *attrString = [[NSAttributedString alloc]initWithString:buy.title attributes:attrsDictionary];
    [buy setAttributedTitle:attrString];
    [result addSubview:buy];
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
