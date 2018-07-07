//
//  updatesTable.m
//  mySIMBL
//
//  Created by Wolfgang Baird on 12/12/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "shareClass.h"
#import "AppDelegate.h"

extern AppDelegate* myDelegate;
extern NSMutableArray *confirmDelete;
extern NSMutableArray *pluginsArray;
extern NSMutableDictionary *needsUpdate;

@interface updatesTable : NSTableView
{
    shareClass *_sharedMethods;
}
@property (weak) IBOutlet NSTableView*  tblView;
- (IBAction)updateAll:(id)sender;
- (IBAction)updatePlugin:(id)sender;
@end

@interface updatesTableCell : NSTableCellView <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSButton*     pluginUpdate;
@property (weak) IBOutlet NSTextField*  pluginName;
@property (weak) IBOutlet NSTextField*  pluginInfo;
@property (weak) IBOutlet NSTextField*  pluginDescription;
@property (weak) IBOutlet NSImageView*  pluginImage;
@end

@implementation updatesTable

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (_sharedMethods == nil)
        _sharedMethods = [shareClass alloc];
    
    needsUpdate = [[NSMutableDictionary alloc] init];
    [self->_sharedMethods checkforPluginUpdates:nil];
    
    return [needsUpdate count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    updatesTableCell *result = (updatesTableCell*)[tableView makeViewWithIdentifier:@"upView" owner:self];
    NSDictionary* item = [needsUpdate objectForKey:[[needsUpdate allKeys] objectAtIndex:row]];
    NSString *bInfo = [NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"version"], [item objectForKey:@"package"]];
    result.pluginName.stringValue = [item objectForKey:@"name"];
    result.pluginInfo.stringValue = bInfo;
    result.pluginDescription.stringValue = [item objectForKey:@"description"];
    result.pluginImage.image = [self->_sharedMethods getbundleIcon:item];
    
    // Return the result
    return result;
}

- (IBAction)updateAll:(id)sender {
    for (NSString* key in [needsUpdate allKeys]) {
        NSDictionary *installDict = [needsUpdate objectForKey:key];
        [self->_sharedMethods pluginInstall:installDict :[installDict objectForKey:@"sourceURL"]];
    }
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.mySIMBL", 0);
    dispatch_async(backgroundQueue, ^{
        [needsUpdate removeAllObjects];
        [self->_sharedMethods checkforPluginUpdates:self->_tblView];
    });
}

- (IBAction)updatePlugin:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    long selected = [t rowForView:sender];
    NSString *key = [[needsUpdate allKeys] objectAtIndex:selected];
    NSDictionary *installDict = [needsUpdate objectForKey:key];
    [self->_sharedMethods pluginInstall:installDict :[installDict objectForKey:@"sourceURL"]];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.mySIMBL", 0);
    dispatch_async(backgroundQueue, ^{
        [needsUpdate removeObjectForKey:key];
        [self->_sharedMethods checkforPluginUpdates:self->_tblView];
    });
}

- (IBAction)reloadUpdates:(id)sender {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.mySIMBL", 0);
    dispatch_async(backgroundQueue, ^{
        [needsUpdate removeAllObjects];
        [self->_sharedMethods checkforPluginUpdates:self->_tblView];
    });
}

@end

@implementation updatesTableCell
@end
