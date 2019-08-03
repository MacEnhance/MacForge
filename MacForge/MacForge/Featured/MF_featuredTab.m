//
//  MF_featuredTab.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;

#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"
#import "MF_featuredTab.h"

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

@implementation MF_featuredTab {
    bool doOnce;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
    PluginManager *_sharedMethods;
    pluginData *_pluginData;
}

-(void)viewWillDraw {
    [NSAnimationContext beginGrouping];
    NSPoint newOrigin = NSMakePoint(0, self.frame.size.height - NSApp.mainWindow.frame.size.height);
    [self.enclosingScrollView.contentView scrollToPoint:newOrigin];
    [NSAnimationContext endGrouping];
    
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
    dispatch_async(backgroundQueue, ^{
        if (self->_sharedMethods == nil)
            self->_sharedMethods = [PluginManager sharedInstance];
        
        // Fetch repo content
        static dispatch_once_t aToken;
        dispatch_once(&aToken, ^{
            self->_pluginData = [pluginData sharedInstance];
            [self->_pluginData fetch_repos];
        });
        
        // Sort table by name
        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->_pluginData.repoPluginsDic allValues]];
        //    dank = [self filterView:dank];
        //    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
        //
        //    // Fetch our local content too
        //    _localPlugins = [_sharedMethods getInstalledPlugins].allKeys;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_viewController1 = [[MF_featuredItemController alloc] initWithNibName:@"MF_featuredItemController" bundle:nil];
            NSView *test = self->_viewController1.view;
            [test setWantsLayer:true];
            [test.layer setBorderColor:NSColor.redColor.CGColor];
            [test.layer setBorderWidth:2];
            [test.layer setCornerRadius:12];
            [self addSubview:test];
            MSPlugin *item = [dank objectAtIndex:0];
            [self->_viewController1 setupWithPlugin:item];
            
            self->_viewController2 = [[MF_featuredItemController alloc] initWithNibName:@"MF_featuredItemController" bundle:nil];
            NSView *test2 = self->_viewController2.view;
            [test2 setWantsLayer:true];
            NSRect newFrame = test2.frame;
            newFrame.origin.y = self.frame.size.height - test2.frame.size.height - 20;
            newFrame.origin.x = 12;
            newFrame.size.width = self.frame.size.width - 30;
            [test2 setFrame:newFrame];
//            [test2.layer setBorderColor:NSColor.redColor.CGColor];
            [test2.layer setBackgroundColor:[NSColor.grayColor colorWithAlphaComponent:0.4].CGColor];
//            [test2.layer setBorderWidth:2];
            [test2.layer setCornerRadius:12];
            [self addSubview:test2];
            MSPlugin *item2 = [dank objectAtIndex:1];
            [self->_viewController2 setupWithPlugin:item2];
            
        });
    });
    

}

@end
