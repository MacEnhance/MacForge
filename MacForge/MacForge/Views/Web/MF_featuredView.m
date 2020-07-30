//
//  MF_webPlguinTableController.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"
#import "MF_featuredView.h"
#import "MF_featuredItemController.h"

extern AppDelegate *myDelegate;

@implementation MF_featuredView {
    int columns;
    MF_Plugin           *plug;
    MF_PluginManager    *sharedMethods;
    MF_repoData         *pluginData;
    NSMutableDictionary *featuredRepo;
    NSArray             *bundles;
    NSMutableArray      *smallArray;
}

- (void)checkAndUpdate {
    if (floor(self.frame.size.width/390.0) != columns || floor(self.frame.size.width/390.0) != _tv.tableColumns.count || columns != _tv.tableColumns.count) {
        columns = floor(self.frame.size.width/390.0);
        [self updateColumCount];
    }
}

- (void)adjustColumnWidth {
    int multiplier = 4;
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion == 11) multiplier = 25;
    NSUInteger pad = self.frame.size.width - (multiplier * columns);
    for (NSTableColumn* c in _tv.tableColumns)
        [c setWidth:pad/columns];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self checkAndUpdate];
    [self adjustColumnWidth];
}

- (void)updateColumCount {
    // remove extra columns
    long nuke = _tv.numberOfColumns - columns;
    if (_tv.numberOfColumns > columns)
        for (int i = 0; i < nuke; i++)
            [_tv removeTableColumn:_tv.tableColumns.lastObject];

    // add needed columns
    long give = columns - _tv.numberOfColumns;
    if (_tv.numberOfColumns < columns) {
        for (int i = 0; i < give; i++) {
            NSString *identify = [NSString stringWithFormat:@"Col%d", (int)_tv.numberOfColumns + 1];
            [_tv addTableColumn:[NSTableColumn.alloc initWithIdentifier:identify]];
        }
    }

    // redraw and fit
    [_tv reloadData];
}

- (void)viewWillDraw {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        columns = 2;
        smallArray = NSMutableArray.new;
        
        // Create a table view
        
        NSRect theFrame = self.frame;
        if (MF_extra.sharedInstance.macOS >= 16) theFrame.size.height += 38;
        
        _tv = [NSTableView.alloc initWithFrame:theFrame];
        _tv.delegate = self;
        _tv.dataSource = self;
        _tv.gridColor = NSColor.clearColor;
        _tv.backgroundColor = NSColor.clearColor;
        _tv.headerView = nil;
        _tv.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
                
        // Create a scroll view and embed the table view in the scroll view, and add the scroll view to our window.
        _sv = [NSScrollView.alloc initWithFrame:theFrame];
        _sv.documentView = _tv;
        _sv.drawsBackground = false;
        _sv.hasVerticalScroller = true;
        _sv.hasHorizontalScroller = false;
        _sv.horizontalScrollElasticity = NSScrollElasticityNone;
        _sv.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:_sv];
        
        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.macenhance.MacForge", 0);
        dispatch_async(backgroundQueue, ^{
            if (!MF_repoData.sharedInstance.hasFetched) {
                [MF_repoData.sharedInstance fetch_repo:MF_REPO_URL];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tv reloadData];
                });
            }
        });
        
        // create columns for our table
        for (int i = 0; i < columns; i++) {
            NSString *identify = [NSString stringWithFormat:@"Col%d", i];
            NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:identify];
            [column setResizingMask:NSTableColumnNoResizing];
            [column setWidth:self.frame.size.width/columns];
            [_tv addTableColumn:column];
        }
    });
    
    [self checkAndUpdate];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    MF_featuredItemController *cont = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
    return cont.view.frame.size.height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSArray *filter = [MF_repoData.sharedInstance fetch_featured:MF_REPO_URL].copy;
    bundles = [MF_repoData.sharedInstance.repoPluginsDic.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleID in %@", filter]];
    return ceil(bundles.count/(float)columns);
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSUInteger index = (row * columns + [[tableView tableColumns] indexOfObject:tableColumn]);
    if (index < bundles.count) {
        MF_featuredItemController *cont = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
        [smallArray addObject:cont];
        NSTableCellView *result = [[NSTableCellView alloc] initWithFrame:cont.view.frame];
        MF_Plugin *p = [[MF_Plugin alloc] init];
        NSUInteger index = (row * columns + [[tableView tableColumns] indexOfObject:tableColumn]);
        if (index < bundles.count) {
            p = [bundles objectAtIndex:index];
            [cont setupWithPlugin:p];
        }
        [result addSubview:cont.view];
        return result;
    }
    return nil;
}

@end
