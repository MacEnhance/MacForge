//
//  MF_pluginPreferencesView.m
//  MacForge
//
//  Created by Wolfgang Baird on 5/21/20.
//  Copyright © 2020 MacEnhance. All rights reserved.
//

#import "MF_pluginPreferencesView.h"
#import "../../../PreferenceLoader/PreferenceLoaderProtocol.h"

@implementation MF_pluginPreferencesView

- (void)viewWillDraw{
    NSTableColumn *yourColumn = self.tv.tableColumns.lastObject;
    [yourColumn.headerCell setStringValue:@"Select a preference bundle"];
//    [self doAQuery];
    [_tv setDelegate:self];
    [_tv setDataSource:self];
    
    _currentPrefView = NULL;
    
    _prefLoaderConnection = [NSXPCSharedListener connectionForListenerNamed:@"com.w0lf.MacForge" fromServiceNamed:@"com.w0lf.MacForge.PreferenceLoader"];
    _prefLoaderConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(PreferenceLoaderProtocol)];
    [_prefLoaderConnection resume];
    
    _prefLoaderProxy = _prefLoaderConnection.remoteObjectProxy;
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
            if(preferenceBundle) {
                [res addObject:preferenceBundle];
            }
//            [res addObject:[@"/Library/Application Support/MacEnhance/Preferences/" stringByAppendingString:file]];
        }
    }
    _pluginList = res.copy;
    return res.count;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {

    if(_currentPrefView)
        [_currentPrefView invalidate];
    
    NSBundle *selectedPref = [_pluginList objectAtIndex:[_tv selectedRow]];
    NSString *path = [selectedPref bundlePath];
    NSLog(@"Bundle path %@", path);
    __weak typeof(self) weakSelf = self;
    
    [_prefLoaderProxy setPluginPath:path
                      withReply:^(BOOL set) {
        NSLog(@"Path Set");
        dispatch_async(dispatch_get_main_queue(), ^(){
            weakSelf.currentPrefView = [[NSRemoteView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            [weakSelf.currentPrefView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [weakSelf.currentPrefView setSynchronizesImplicitAnimations:NO];
            [weakSelf.currentPrefView setShouldMaskToBounds:NO];
            [weakSelf.currentPrefView setServiceName:@"com.w0lf.MacForge.PreferenceLoader"];
            [weakSelf.currentPrefView setServiceSubclassName:@"PreferenceLoaderServiceView"];
            
            [weakSelf.currentPrefView advanceToRunPhaseIfNeeded:^(NSError *err){
                dispatch_async(dispatch_get_main_queue(), ^(){
                    NSRect frame = weakSelf.currentPrefView.frame;
                    frame.origin.y = weakSelf.preferencesContainer.frame.size.height - frame.size.height;
                    [weakSelf.currentPrefView setFrame:frame];
                    [weakSelf.preferencesContainer addSubview:weakSelf.currentPrefView];
                });
            }];
        });
    }];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *result = [[NSTableCellView alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    NSImageView *img = [[NSImageView alloc] initWithFrame:CGRectMake(5, 3, 24, 24)];
    
    NSString *bundleID = @"";
    NSString *appPath = @"";
    appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:bundleID];

    NSImage *appIMG = NSImage.new;
    NSString *appName = @"";
        
    if (appPath.length) {
        appIMG = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        if (appIMG == nil)
            appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        NSBundle *bundle = [NSBundle bundleWithPath:appPath];
        NSDictionary *info = [bundle infoDictionary];
        appName = [info objectForKey:@"CFBundleExecutable"];
    } else {
        appIMG = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"];
        appName = bundleID;
    }

    NSTextField *appNameView = [[NSTextField alloc] initWithFrame:CGRectMake(32, 5, 200, 20)];
    appNameView.editable = NO;
    appNameView.bezeled = NO;
    [appNameView setSelectable:false];
    [appNameView setDrawsBackground:false];
    appNameView.stringValue = [[(NSBundle *)(_pluginList[row]) executablePath] lastPathComponent];

    [img setImage:appIMG];
    [result addSubview:appNameView];
    [result addSubview:img];

    return result;
}

@end
