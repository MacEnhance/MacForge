//
//  MF_localCollection.m
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "MF_localCollection.h"


@implementation MF_localCollectionViewManager

- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView
                        layout:(NSCollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return NSEdgeInsetsMake(10, 10, 10, 10);
}

- (NSSize)collectionView:(NSCollectionView *)collectionView
                  layout:(NSCollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(175, 77);
}

- (NSString*)runScript:(NSString*)script {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/lipo";
    task.arguments = @[@"-archs", script];
    task.standardOutput = pipe;
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

- (nonnull NSCollectionViewItem *)collectionView:(nonnull NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MF_localPlugin *item = [collectionView makeItemWithIdentifier:@"MF_localPlugin" forIndexPath:indexPath];
    MF_Plugin *plug = [self.itemArray objectAtIndex:indexPath.item];
    item.bundleName.stringValue = plug.localName;
    if([plug.localPath length]) {
        if (plug.isEnabled) {
            [item.bundleEnabled setState:NSControlStateValueOn];
        } else {
            [item.bundleEnabled setState:NSControlStateValueOff];
        }
        
        NSBundle *bun = [NSBundle bundleWithPath:plug.localPath];
        NSString *archs = [self runScript:bun.executablePath];
        if ([archs containsString:@"arm64e"]) {
            item.bundleSupportsARM.image = [NSImage imageNamed:NSImageNameStatusAvailable];
        } else if ([archs containsString:@"arm64"]) {
            item.bundleSupportsARM.image = [NSImage imageNamed:NSImageNameStatusPartiallyAvailable];
        } else {
            item.bundleSupportsARM.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
        }
//        if ([bun.executableArchitectures containsObject:[NSNumber numberWithInt:0x0100000c]])
//            item.bundleSupportsARM.image = [NSImage imageNamed:NSImageNameStatusAvailable];
//        else
//            item.bundleSupportsARM.image = [NSImage imageNamed:NSImageNameStatusUnavailable];
        
        item.bundleIcon.image = [_pluginData fetch_icon:plug];
        item.bundleVersion.stringValue = [bun.infoDictionary valueForKey:@"CFBundleShortVersionString"];
        item.bundleIdentifier.stringValue = bun.bundleIdentifier;
        
        item.bundlePlugin = plug;
    }
    
    item.view.wantsLayer = true;
    item.view.layer.backgroundColor = [NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.2].CGColor;
    item.view.layer.cornerRadius = 8;
    
    return item;
}

//- (NSArray*)filterView:(NSArray*)original {
//    NSString *filterText = _pluginFilter.stringValue;
//    NSArray *result = original;
//    if (filterText.length > 0)
//        result = [original filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(localName CONTAINS[cd] %@) OR (bundleID CONTAINS[cd] %@)", filterText, filterText]];
//    return result;
//}

- (NSInteger)collectionView:(nonnull NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_sharedMethods == nil)
        _sharedMethods = [MF_PluginManager sharedInstance];
    
    _pluginData = [MF_repoData sharedInstance];
    [_pluginData fetch_local];
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"localName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *dank = [[NSMutableArray alloc] initWithArray:[_pluginData.localPluginsDic allValues]];
    // dank = [self filterView:dank];
    self.itemArray = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
    return self.itemArray.count;
}

@end

@implementation MF_localCollection

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
