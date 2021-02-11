//
//  MF_featuredCollection.m
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "AppDelegate.h"
#import "MF_featuredItemController.h"
#import "MF_featuredCollection.h"
#import "MF_featuredItem.h"

@implementation MF_featuredCollectionViewManager

//- (NSEdgeInsets)collectionView:(NSCollectionView *)collectionView
//                        layout:(NSCollectionViewLayout *)collectionViewLayout
//        insetForSectionAtIndex:(NSInteger)section {
//    return NSEdgeInsetsMake(10, 10, 10, 10);
//}

//- (NSSize)collectionView:(NSCollectionView *)collectionView
//                  layout:(NSCollectionViewLayout *)collectionViewLayout
//  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//     NSLog(@"%f", collectionView.frame.size.width);
//    return CGSizeMake(300, 300);
//}

- (nonnull NSCollectionViewItem *)collectionView:(nonnull NSCollectionView *)collectionView itemForRepresentedObjectAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MF_featuredItem *item = [collectionView makeItemWithIdentifier:@"MF_featuredItem" forIndexPath:indexPath];
    [item setupWithPlugin:[self.bundles objectAtIndex:indexPath.item]];
    return item;
}

- (NSInteger)collectionView:(nonnull NSCollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.macenhance.MacForge", 0);
    dispatch_async(backgroundQueue, ^{
        if (!MF_repoData.sharedInstance.hasFetched) {
            [MF_repoData.sharedInstance fetch_repo:MF_REPO_URL];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.view reloadData];
            });
        }
    });
    
    NSArray *filter = [MF_repoData.sharedInstance fetch_featured:MF_REPO_URL].copy;
    self.bundles = [MF_repoData.sharedInstance.repoPluginsDic.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bundleID in %@", filter]];
    return self.bundles.count;
}

@end

@implementation MF_featuredCollection

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {    
    [self.window addObserver:self forKeyPath:@"firstResponder" options:NSKeyValueObservingOptionNew context:nil];
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeFileURL, kUTTypeFileURL, nil]];
    [self reloadData];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
