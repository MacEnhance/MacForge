//
//  MF_localPlugin.m
//  MacForge
//
//  Created by Wolfgang Baird on 2/4/21.
//  Copyright © 2021 MacEnhance. All rights reserved.
//

#import "MF_localPlugin.h"

@interface MF_localPlugin ()

@end

@implementation MF_localPlugin

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)pluginToggle:(id)sender {
    NSString *name = self.bundlePlugin.localName;
    NSString *path = self.bundlePlugin.localPath;
    NSArray *paths = [MF_PluginManager MacEnhancePluginPaths];
    NSInteger respath = 0;
    if (self.bundlePlugin.isUser) respath = 2;
    if (self.bundlePlugin.isEnabled) respath += 1;
    [MF_PluginManager.sharedInstance replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
}

- (IBAction)pluginFinder:(id)sender {
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:self.bundlePlugin.localPath];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
}

//- (IBAction)pluginDelete:(id)sender {
//    NSURL* url = [NSURL fileURLWithPath:self.bundlePlugin.localPath];
//    NSURL* trash;
//    NSError* error;
//    [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
//}
//
//- (IBAction)pluginLocToggle:(id)sender {
//    MF_Plugin *plug = [_tableContent objectAtIndex:(long)[_tblView rowForView:sender]];
//    NSString *name = plug.localName;
//    NSString *path = plug.localPath;
//    NSArray *paths = [MF_PluginManager MacEnhancePluginPaths];
//    NSInteger respath = 0;
//    if (!plug.isUser) respath = 2;
//    if (!plug.isEnabled) respath += 1;
//    [_sharedMethods replaceFile:path :[NSString stringWithFormat:@"%@/%@.bundle", paths[respath], name]];
//}

@end
