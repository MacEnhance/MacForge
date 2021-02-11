//
//  MF_featuredCollection.h
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredCollection : NSCollectionView

@end

@interface MF_featuredCollectionViewManager : NSObject <NSCollectionViewDelegate, NSCollectionViewDataSource>

@property IBOutlet MF_featuredCollection    *view;
@property NSArray                           *bundles;

@end

NS_ASSUME_NONNULL_END
