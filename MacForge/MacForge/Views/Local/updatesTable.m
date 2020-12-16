//
//  updatesTable.m
//  MacForge
//
//  Created by Wolfgang Baird on 12/12/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import "MF_PluginManager.h"
#import "AppDelegate.h"

extern AppDelegate* myDelegate;
extern NSMutableArray *pluginsArray;
NSMutableDictionary *needsUpdate;

@interface updatesTable : NSTableView {
    MF_PluginManager *sharedMethods;
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
    if (sharedMethods == nil)
        sharedMethods = [MF_PluginManager sharedInstance];
    
    [sharedMethods checkforPluginUpdates:nil :myDelegate.viewUpdateCounter];
    needsUpdate = sharedMethods.getNeedsUpdate;
    
    return [needsUpdate count];
}

- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self tableView:tableView viewForTableColumn:tableColumn row:row];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    updatesTableCell *result = (updatesTableCell*)[tableView makeViewWithIdentifier:@"upView" owner:self];
    NSDictionary* item = [needsUpdate objectForKey:[[needsUpdate allKeys] objectAtIndex:row]];
    result.pluginName.stringValue = [item objectForKey:@"name"];
    result.pluginInfo.stringValue = [item objectForKey:@"package"];
    result.pluginDescription.stringValue = [NSString stringWithFormat:@"%@ --- %@", [sharedMethods getItemLocalVersion:item[@"package"]], [item objectForKey:@"version"]];
    result.pluginImage.image = [MF_PluginManager pluginGetIcon:item];
    
    // Return the result
    return result;
}

- (void)updatePluginAllPlugins:(int)pluginNumber {
    if (pluginNumber < needsUpdate.count) {
        NSDictionary *installDict = [needsUpdate objectForKey:[needsUpdate.allKeys objectAtIndex:pluginNumber]];
        [self->sharedMethods pluginUpdateOrInstall:installDict withCompletionHandler:^(BOOL res) {
            [self updatePluginAllPlugins:pluginNumber + 1];
        }];
    } else {
        [needsUpdate removeAllObjects];
        [self reloadData];
    }
//
}

- (IBAction)updateAll:(id)sender {
    [self updatePluginAllPlugins:0];
}

- (IBAction)updatePlugin:(id)sender {
    NSTableView *t = (NSTableView*)[[[sender superview] superview] superview];
    long selected = [t rowForView:sender];
    @try {
        __block NSUInteger count = [needsUpdate count];
        
        NSString *key = [[needsUpdate allKeys] objectAtIndex:selected];
        NSDictionary *installDict = [needsUpdate objectForKey:key];
        [self->sharedMethods pluginUpdateOrInstall:installDict withCompletionHandler:^(BOOL res) {
            count--;
        }];
        
        /* wait until all installs have finished */
//        while (count > 0) NSLog(@"%lu", (unsigned long)count);
        
        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.macenhance.MacForge", 0);
        dispatch_async(backgroundQueue, ^{
            [self->sharedMethods checkforPluginUpdates:self->_tblView :myDelegate.viewUpdateCounter];
        });
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    } @finally {
        // Do nothing
    }
}

- (IBAction)reloadUpdates:(id)sender {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.macenhance.MacForge", 0);
    dispatch_async(backgroundQueue, ^{
//        [needsUpdate removeAllObjects];
        [self->sharedMethods checkforPluginUpdates:self->_tblView :myDelegate.viewUpdateCounter];
    });
}

@end

@implementation updatesTableCell
@end
