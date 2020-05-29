//
//  MF_searchView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/22/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"
#import "MF_bundleTinyItem.h"
#import "MF_searchView.h"

extern AppDelegate *myDelegate;

@implementation MF_searchView {
    int                 columns;
    MF_repoData         *pluginData;
    NSMutableArray      *smallArray;
    NSArray             *bundles;
    NSArray             *tableContents;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSUInteger pad = self.frame.size.width - (4 * columns);
    for (NSTableColumn* c in self.tv.tableColumns)
        [c setWidth:pad/columns];
    [_tv setFrame:CGRectMake(0, 0, self.frame.size.width, _tv.frame.size.height)];
}

- (void)updateColumCount {
    // remove extra columns
    if (_tv.numberOfColumns > columns)
        for (int i = 0; i < _tv.numberOfColumns - columns; i++)
            [_tv removeTableColumn:_tv.tableColumns.lastObject];
    
    // add needed columns
    if (_tv.numberOfColumns < columns) {
        for (int i = 0; i < columns - _tv.numberOfColumns; i++) {
            NSString *identify = [NSString stringWithFormat:@"Col%d", (int)_tv.numberOfColumns + 1];
            NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:identify];
            [column setWidth:self.frame.size.width/columns];
            [_tv addTableColumn:column];
        }
    }
    
    // set columns to equal width
    for (NSTableColumn *col in _tv.tableColumns) {
        [col setWidth:self.frame.size.width/columns];
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
        _tv = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)];
        _tv.delegate = self;
        _tv.dataSource = self;
        _tv.gridColor = NSColor.clearColor;
        _tv.backgroundColor = NSColor.clearColor;
        _tv.headerView = nil;
        
        // Create a scroll view and embed the table view in the scroll view, and add the scroll view to our window.
        NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:self.frame];
        tableContainer.documentView = _tv;
        tableContainer.drawsBackground = false;
        tableContainer.hasVerticalScroller = true;
        tableContainer.hasHorizontalScroller = false;
        tableContainer.horizontalScrollElasticity = NSScrollElasticityNone;
        tableContainer.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self addSubview:tableContainer];
        
        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
        dispatch_async(backgroundQueue, ^{
            if (!MF_repoData.sharedInstance.hasFetched) {
                [MF_repoData.sharedInstance fetch_repo:@"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo"];
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
    
    if (floor(self.frame.size.width/390.0) != columns) {
        columns = floor(self.frame.size.width/390.0);
        [self updateColumCount];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    MF_bundleTinyItem *cont = [[MF_bundleTinyItem alloc] initWithNibName:0 bundle:nil];
    return cont.view.frame.size.height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    bundles = MF_repoData.sharedInstance.repoPluginsDic.allValues;    
    if (_filter.length > 0) {
        // Filter bundles
        // Should add author
        NSString *filter = @"(webName CONTAINS[cd] %@) OR (bundleID CONTAINS[cd] %@) OR (webTarget CONTAINS[cd] %@)";
        bundles = [bundles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:filter, _filter, _filter, _filter]];
        
        // Sort results by name
        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        bundles = [[bundles sortedArrayUsingDescriptors:@[sorter]] copy];
    }
    return ceil(bundles.count/(float)columns);
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSUInteger index = (row * columns + [[tableView tableColumns] indexOfObject:tableColumn]);
    if (index < bundles.count) {
        
        if ([[[bundles objectAtIndex:index] class] isEqualTo:MF_Plugin.class]) {
            MF_bundleTinyItem *cont = [[MF_bundleTinyItem alloc] initWithNibName:0 bundle:nil];
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
