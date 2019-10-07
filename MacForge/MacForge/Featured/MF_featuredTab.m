//
//  MF_featuredTab.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;

@import GameplayKit;

#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"
#import "MF_featuredTab.h"

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

@implementation MF_featuredTab {
    bool doOnce;
    Boolean needsRefresh;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
    PluginManager *_sharedMethods;
    pluginData *_pluginData;
    NSMutableDictionary *featuredRepo;
}

-(void)awakeFromNib {
    //    [NSAnimationContext beginGrouping];
        NSPoint newOrigin = NSMakePoint(0, self.frame.size.height - self.superview.frame.size.height);
        [self.enclosingScrollView.contentView scrollToPoint:newOrigin];
    //    [NSAnimationContext endGrouping];
    //    [self setSubviews:[NSArray array]];
    
        static dispatch_once_t aToken;
        dispatch_once(&aToken, ^{
            self->needsRefresh = true;
        });

        if (needsRefresh) {
            needsRefresh = false;
            
            _smallArray = [[NSMutableArray alloc] init];
            _largeArray = [[NSMutableArray alloc] init];
            
            dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
            dispatch_async(backgroundQueue, ^{
                if (self->_sharedMethods == nil)
                    self->_sharedMethods = [PluginManager sharedInstance];
                
                // Fetch repo content
                static dispatch_once_t aToken;
                dispatch_once(&aToken, ^{
                    self->_pluginData = [pluginData sharedInstance];
                    [self->_pluginData fetch_repos];
                    self->featuredRepo = [self->_pluginData fetch_repo:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo"];
                });
                
    //            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                NSArray *dank = [[NSArray alloc] initWithArray:[self->featuredRepo allValues]];
//                dank = [dank shuffledArray];
                
                // Sort by price decending
                NSMutableArray *mute = dank.mutableCopy;
                [mute sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"webPrice" ascending:NO] ]];
                
//                for (MSPlugin* p in mute)
//                    NSLog(@"%@ : %@", p.webPrice, p.bundleID);
                
                dank = mute.copy;
                
//                NSLog(@"%@", self->featuredRepo.allKeys);
//                for (MSPlugin* p in dank) {
//                    NSLog(@"%@", p.bundleID);
//                }
//                NSLog(@"%@", dank);
                
                // Sort table by name
                //        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                //        NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->_pluginData.repoPluginsDic allValues]];
                //    dank = [self filterView:dank];
                //    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
                //
                //    // Fetch our local content too
                //    _localPlugins = [_sharedMethods getInstalledPlugins].allKeys;
                
                dispatch_async(dispatch_get_main_queue(), ^{

                    int totalHeight = self.frame.size.height + 20;
                    
                    // Background color if no background image provided
                    struct CGColor *clr = [NSColor.grayColor colorWithAlphaComponent:0.4].CGColor;
                    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
                    if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 14)
                        if ([osxMode isEqualToString:@"Dark"]) clr = [NSColor.whiteColor colorWithAlphaComponent:0.1].CGColor;
                    
                    // Setup large featured item
                    MF_featuredItemController *lrg = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
                    for (int i = 0; i < 3; i++) {
                        [self createLargeItem:dank :i :totalHeight :clr];
                        totalHeight -= lrg.view.frame.size.height + 20;
                    }
                    totalHeight -= lrg.view.frame.size.height;
                   
                    MF_featuredSmallController *sml = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
                    for (int i = 3; i < dank.count; i++) {
                        [self createSmallItem:dank :i :totalHeight :clr];
                        if (i % 2 == 0)
                            totalHeight -= sml.view.frame.size.height + 20;
                    }
                    if (dank.count % 2 != 0)
                        totalHeight += sml.view.frame.size.height;
                    else
                        totalHeight -= 20;
                    
                    // Correct view height and scroll to top
                    int newHeight = self.frame.size.height - totalHeight;
                    [self setFrameSize:CGSizeMake(self.frame.size.width, newHeight)];
                    [self scrollPoint:CGPointMake(0, self.frame.size.height)];
                });
            });
        }
            
}

-(void)createSmallItem:(NSArray*)array :(int)index :(int)position :(struct CGColor*)clr {
    MF_featuredSmallController *cont = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
    [self.smallArray addObject:cont];
    
    NSRect newFrame;
    NSView *test = [cont view];
    [test setWantsLayer:true];
    newFrame = test.frame;
    //                ypos = self.frame.size.height - ((test.frame.size.height + 20) * (i / 2)) - totalHeight;
    int ypos = position;
    int xpos;
    if (index % 2 != 0) {
        xpos = 12;
        [test setAutoresizingMask:test.autoresizingMask|NSViewMaxXMargin];
    } else {
        xpos = (self.frame.size.width / 2) + 5;
        [test setAutoresizingMask:test.autoresizingMask|NSViewMinXMargin];
    }
    newFrame.size.width = (self.frame.size.width / 2) - 25;
    newFrame.origin.y = ypos;
    newFrame.origin.x = xpos;
    [test setFrame:newFrame];
    [test.layer setBackgroundColor:clr];
    [test.layer setCornerRadius:12];
    [self addSubview:test];
    
    MSPlugin *p = [[MSPlugin alloc] init];
    if (index < array.count) {
        p = [array objectAtIndex:index];
        [cont setupWithPlugin:p];
    }
}

-(void)createLargeItem:(NSArray*)array :(int)index :(int)position :(struct CGColor*)clr {
    MF_featuredItemController *cont = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
    [self.largeArray addObject:cont];
    
    NSView *test2 = cont.view;
    [test2 setWantsLayer:true];
    [test2 setFrame:CGRectMake(12, position - test2.frame.size.height - 50, self.frame.size.width - 30, 180)];
    [test2.layer setBackgroundColor:clr];
    [test2.layer setCornerRadius:12];
    [self addSubview:test2];
    
    MSPlugin *p = [[MSPlugin alloc] init];
    if (index < array.count) {
        p = [array objectAtIndex:index];
        [cont setupWithPlugin:p];
    }
}

//-(void)viewWillDraw {
//}

@end
