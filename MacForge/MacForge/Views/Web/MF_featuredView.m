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

int columns = 3;

@implementation MF_featuredView {
    MF_Plugin           *plug;
    MF_PluginManager    *sharedMethods;
    MF_repoData         *pluginData;
    NSMutableDictionary *featuredRepo;
    NSArray             *bundles;
    NSMutableArray      *smallArray;
}

- (void)viewWillDraw {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        smallArray = NSMutableArray.new;
        
        // create a table view and a scroll view
        NSScrollView * tableContainer = [[NSScrollView alloc] initWithFrame:self.frame];
        tableContainer.drawsBackground = false;
        
        _tv = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 700, 500)];
        [_tv setDelegate:self];
        [_tv setDataSource:self];
        _tv.gridColor = NSColor.clearColor;
        _tv.backgroundColor = NSColor.clearColor;
        _tv.headerView = nil;
        
        // embed the table view in the scroll view, and add the scroll view to our window.
        [tableContainer setDocumentView:_tv];
        [tableContainer setHasVerticalScroller:YES];
        [self addSubview:tableContainer];
        
        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
        dispatch_async(backgroundQueue, ^{
            if (self->sharedMethods == nil)
                self->sharedMethods = [MF_PluginManager sharedInstance];

            // Fetch repo content
            static dispatch_once_t aToken;
            dispatch_once(&aToken, ^{
                self->pluginData = [MF_repoData sharedInstance];
                [self->pluginData fetch_repos];
                self->featuredRepo = [self->pluginData fetch_repo:@"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo"];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tv reloadData];
                });
            });
        });
    });
    
    // create columns for our table
    for (int i = 0; i < columns; i++) {
        NSString *identify = [NSString stringWithFormat:@"Col%d", i];
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:identify];
        [column setWidth:self.frame.size.width/columns];
        [_tv addTableColumn:column];
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    MF_featuredItemController *cont = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
    return cont.view.frame.size.height;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSArray *dank = [[NSArray alloc] initWithArray:[self->featuredRepo allValues]];
    NSArray *filter = [MF_repoData.sharedInstance fetch_featured:@"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo"].copy;
    NSArray *result = [dank filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleID in %@", filter]];
    bundles = result;
    return ceil(result.count/columns);
//    result.count;
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
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

@end
