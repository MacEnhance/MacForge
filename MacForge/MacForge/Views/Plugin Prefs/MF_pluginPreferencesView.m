//
//  MF_pluginPreferencesView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "MF_pluginPreferencesView.h"

@implementation MF_pluginPreferencesView

- (void)viewWillDraw{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [_tv setDelegate:self];
        [_tv setDataSource:self];
        [_tv registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        [_tv.tableColumns.lastObject.headerCell setStringValue:@"Select a preference bundle"];
        self.watchDog = [[SGDirWatchdog alloc] initWithPath:@"/Library/Application Support/MacEnhance/Preferences" update:^{
            [self.tv reloadData];
        }];
        [self.watchDog start];
    });
    
    _preferencesContainer.wantsLayer = true;
    _preferencesContainer.layer.borderColor = NSColor.grayColor.CGColor;
    _preferencesContainer.layer.borderWidth = 1;
    
    _currentPrefView = NULL;
    
    // Prevent selection until helper is running
//    [self.tv setEnabled:false];
    
//    __weak typeof(self) weakSelf = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        weakSelf.prefLoaderConnection = [NSXPCSharedListener connectionForListenerNamed:@"com.macenhance.MacForge" fromServiceNamed:@"com.macenhance.MacForge.PreferenceLoader"];
//        weakSelf.prefLoaderConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PreferenceLoaderProtocol)];
//        @try { [weakSelf.prefLoaderConnection resume]; }
//        @catch (NSException *exception) { NSLog(@"Yikes"); }
//        weakSelf.prefLoaderProxy = weakSelf.prefLoaderConnection.remoteObjectProxy;
//
//        dispatch_async(dispatch_get_main_queue(), ^(){
//            // Enable selection
//            [self.tv setEnabled:true];
//
            // Automatically select the first row (if one exists) once we're done loading
            if (self.tv.selectedRow < 0) {
                if (self.tv.numberOfRows > 0) {
                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:0];
                    [self.tv selectRowIndexes:indexSet byExtendingSelection:NO];
                }
            }
//        });
//    });
    
    _prefLoaderProxy = _prefLoaderConnection.remoteObjectProxy;
}

- (IBAction)revealOrRemove:(NSSegmentedControl*)sender {
    NSBundle *selectedPref = [_pluginList objectAtIndex:[_tv selectedRow]];
    NSString *path = [selectedPref bundlePath];
    
    // Reveal
    if (sender.selectedSegment == 0) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:[path stringByExpandingTildeInPath]]]];
    }
    
    // Remove
    if (sender.selectedSegment == 1) {
        NSURL* url = [NSURL fileURLWithPath:path];
        NSURL* trash;
        NSError* error;
        [[NSFileManager defaultManager] trashItemAtURL:url resultingItemURL:&trash error:&error];
    }
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType]) {
        NSArray* urls = [pboard readObjectsForClasses:@[[NSURL class]] options:nil];
        NSMutableArray* sorted = [[NSMutableArray alloc] init];
        for (NSURL* url in urls) {
            if ([[url.path pathExtension] isEqualToString:@"bundle"])
                [sorted addObject:url.path];
        }
        if ([sorted count])
            [MF_PluginManager.sharedInstance installBundles:sorted];
    }
    return YES;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 30;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSMutableArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Application Support/MacEnhance/Preferences" error:Nil].mutableCopy;
    NSMutableArray *res = NSMutableArray.new;
    for (NSString *file in dirs) {
        if ([file.pathExtension isEqualToString:@"bundle"]) {
            NSBundle *preferenceBundle = [NSBundle bundleWithPath:[@"/Library/Application Support/MacEnhance/Preferences/" stringByAppendingString:file]];
            if (preferenceBundle)
                [res addObject:preferenceBundle];
        }
    }
    _pluginList = res.copy;
    return res.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [_seg setEnabled:(_tv.selectedRow >= 0)];
    
    // Clear the view
    if(_currentPrefView) {
        [_currentPrefView invalidate];
        _currentPrefView = NULL;
    }
        
    // Load view if there is a selected item
    if (_tv.selectedRow >= 0) {
        NSBundle *selectedPref = [_pluginList objectAtIndex:[_tv selectedRow]];
        NSString *path = [selectedPref bundlePath];
        NSLog(@"Bundle path %@", path);
        
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        Class someClass = [bundle principalClass];
        NSString *nib = path.lastPathComponent.stringByDeletingPathExtension;
        NSLog(@"Nib name %@", nib);

        id instance = [[someClass alloc] initWithNibName:nib bundle:bundle];
        NSViewController *testVC = (NSViewController*)instance;
        if (![instance isKindOfClass:[NSViewController class]]) {
            NSLog(@"Bad class??");
        }
        @try {
            [MF_extra.sharedInstance setViewSubViewWithScrollableView:self.preferencesContainer :testVC.view];
        } @catch (NSException *exception) {

        }
        
//        __weak typeof(self) weakSelf = self;
//
//        [_prefLoaderProxy setPluginPath:path
//                          withReply:^(BOOL set) {
//            NSLog(@"Path Set");
//            dispatch_async(dispatch_get_main_queue(), ^(){
//                weakSelf.currentPrefView = [[NSRemoteView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
////                [weakSelf.currentPrefView setTranslatesAutoresizingMaskIntoConstraints:NO];
//                [weakSelf.currentPrefView setSynchronizesImplicitAnimations:NO];
//                [weakSelf.currentPrefView setShouldMaskToBounds:NO];
//                [weakSelf.currentPrefView setServiceName:@"com.macenhance.MacForge.PreferenceLoader"];
//                [weakSelf.currentPrefView setServiceSubclassName:@"PreferenceLoaderServiceView"];
//
//                [weakSelf.currentPrefView advanceToRunPhaseIfNeeded:^(NSError *err){
//                    dispatch_async(dispatch_get_main_queue(), ^(){
//                        [MF_extra.sharedInstance setViewSubViewWithScrollableView:weakSelf.preferencesContainer :weakSelf.currentPrefView];
//                    });
//                }];
//            });
//        }];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    NSImageView *img = [[NSImageView alloc] initWithFrame:CGRectMake(5, 3, 24, 24)];
    
    NSString *bundleID  = @"";
    NSString *appName   = @"";
    NSString *appPath   = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];
    NSImage *appIMG     = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/KEXT.icns"];
        
    if (appPath.length) {
        appName = [[NSBundle bundleWithPath:appPath].infoDictionary objectForKey:@"CFBundleExecutable"];
    } else {
        appName = bundleID;
    }

    NSTextField *appNameView = [[NSTextField alloc] initWithFrame:CGRectMake(32, 5, 200, 20)];
    appNameView.editable = NO;
    appNameView.bezeled = NO;
    [appNameView setSelectable:false];
    [appNameView setDrawsBackground:false];
    appNameView.stringValue = [[(NSBundle *)(_pluginList[row]) executablePath] lastPathComponent];

//    NSButton *toggle = [NSButton.alloc initWithFrame:CGRectMake(60, 5, 20, 20)];
//    [toggle setButtonType:NSButtonTypeSwitch];
//    [toggle setAutoresizingMask:NSViewMinXMargin];
//    [result addSubview:toggle];
    
    [img setImage:appIMG];
    [result addSubview:appNameView];
    [result addSubview:img];

    return result;
}

@end
