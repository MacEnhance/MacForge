//
//  MF_purchasedView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/29/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"
#import "MF_purchasedItem.h"
#import "MF_purchasedView.h"

@implementation MF_purchasedView {
    int                 columns;
    MF_repoData         *pluginData;
    NSMutableArray      *smallArray;
    NSArray             *bundles;
    NSArray             *tableContents;
}

- (void)checkAndUpdate {
    if (floor(self.frame.size.width/350.0) != columns || floor(self.frame.size.width/350.0) != _tv.tableColumns.count || columns != _tv.tableColumns.count) {
        columns = floor(self.frame.size.width/350.0);
        [self updateColumCount];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    NSUInteger pad = self.frame.size.width - (4 * columns);
    for (NSTableColumn* c in self.tv.tableColumns)
        [c setWidth:pad/columns];
    [self checkAndUpdate];
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
            NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:identify];
            [column setWidth:self.frame.size.width/columns];
            [_tv addTableColumn:column];
        }
    }
    
    // set columns to equal width
    for (NSTableColumn *col in _tv.tableColumns)
        [col setWidth:self.frame.size.width/columns];
    
    // redraw and fit
    [_tv reloadData];
}

- (void)viewWillDraw {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        columns = 2;
        smallArray = NSMutableArray.new;
        
        // Create a table view
        _tv = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
        _tv.delegate = self;
        _tv.dataSource = self;
        _tv.gridColor = NSColor.clearColor;
        _tv.backgroundColor = NSColor.clearColor;
        _tv.headerView = nil;
        _tv.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
        
        // Create a scroll view and embed the table view in the scroll view, and add the scroll view to our window.
        NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:self.frame];
        tableContainer.documentView = _tv;
        tableContainer.drawsBackground = false;
        tableContainer.hasVerticalScroller = true;
        tableContainer.hasHorizontalScroller = false;
        tableContainer.horizontalScrollElasticity = NSScrollElasticityNone;
        tableContainer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:tableContainer];
        
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
            [column setWidth:self.frame.size.width/columns];
            [_tv addTableColumn:column];
        }
    });
    
//    [_tv reloadData];
    [self checkAndUpdate];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    MF_purchasedItem *cont = [[MF_purchasedItem alloc] initWithNibName:0 bundle:nil];
    return cont.view.frame.size.height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    bundles = MF_repoData.sharedInstance.repoPluginsDic.allValues;
    bundles = [bundles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(hasPurchased == %@)", [NSNumber numberWithBool:true]]];
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    bundles = [[bundles sortedArrayUsingDescriptors:@[sorter]] copy];
    return ceil(bundles.count/(float)columns);
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSUInteger index = (row * columns + [[tableView tableColumns] indexOfObject:tableColumn]);
    if (index < bundles.count) {
        
        if ([[[bundles objectAtIndex:index] class] isEqualTo:MF_Plugin.class]) {
            MF_purchasedItem *cont = [[MF_purchasedItem alloc] initWithNibName:0 bundle:nil];
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
        
    }
    return nil;
    
}

@end

