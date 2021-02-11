//
//  MF_localCollection.h
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MF_localPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface MF_localCollection : NSCollectionView

@end

@interface MF_localCollectionViewManager : NSObject <NSCollectionViewDelegate, NSCollectionViewDataSource> {
    MF_PluginManager *_sharedMethods;
    MF_repoData *_pluginData;
    NSArray *image_array;
    NSImage *user;
    NSImage *group;
}

@property IBOutlet MF_localCollection   *view;
@property NSArray                       *itemArray;

@end

NS_ASSUME_NONNULL_END
